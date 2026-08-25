import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:receipts/core/logging/error_log_service.dart';
import 'package:receipts/data/database.dart';
import 'package:receipts/data/repositories/analytics_repository.dart';
import 'package:receipts/data/repositories/receipt_repository.dart';
import 'package:receipts/domain/models/import_result.dart';
import 'package:receipts/domain/parsing/receipt_parser.dart';
import 'package:receipts/features/import/import_service.dart';
import 'package:receipts/platform/pdf_text_extractor/pdf_text_extractor.dart';
import 'helpers/test_environment.dart';

class _MockPdfTextExtractor extends Mock implements PdfTextExtractor {}

void main() {
  late TestAppHarness harness;
  late ReceiptRepository receiptRepository;
  late AnalyticsRepository analyticsRepository;
  late ImportService importService;
  late _MockPdfTextExtractor pdf;

  setUpAll(() async {
    await bootstrapTestEnvironment();
  });

  setUp(() async {
    pdf = _MockPdfTextExtractor();
    harness = TestAppHarness();
    await harness.setUp();

    receiptRepository = ReceiptRepository(harness.container.read);
    analyticsRepository = AnalyticsRepository(harness.container.read);
    importService = ImportService(
      pdf: pdf,
      parser: ReceiptParser(),
      receipts: receiptRepository,
      analytics: analyticsRepository,
      errorLogger: ErrorLogService(enabled: false),
    );

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, DatabaseHelper.dbName);
    if (await File(path).exists()) {
      await databaseFactory.deleteDatabase(path);
    }
    await DatabaseHelper.database;
  });

  tearDown(() async {
    await harness.tearDown();
  });

  test(
      'imports receipt, persists data, updates aggregates, prevents duplicates',
      () async {
    final sampleText = await File('assets/sample_receipt.txt').readAsString();

    when(() => pdf.fileHash('uri://sample'))
        .thenAnswer((_) async => 'sample-receipt-hash');
    when(() => pdf.extractTextPages('uri://sample'))
        .thenAnswer((_) async => [sampleText]);
    when(() => pdf.pageCount('uri://sample')).thenAnswer((_) async => 1);

    final firstImport = await importService.importOne('uri://sample');

    expect(firstImport.status, ImportStatus.success);
    expect(firstImport.receiptId, isNotEmpty);

    final db = await DatabaseHelper.database;
    final receipts = await db.query('receipts');
    expect(receipts.length, 1);
    final items = await db.query('line_items');
    expect(items.length, greaterThan(0));

    final monthlyTotals = await db.query(
      'monthly_totals',
      where: 'year = ? AND month = ?',
      whereArgs: [2025, 8],
    );
    expect(monthlyTotals.length, 1);
    final monthlyTotal = (monthlyTotals.first['total'] as num).toDouble();
    expect(monthlyTotal, closeTo(23.40, 0.01));

    final categoryTotals = await db.query(
      'category_month_totals',
      where: 'year = ? AND month = ?',
      whereArgs: [2025, 8],
    );
    expect(categoryTotals, isNotEmpty);

    final duplicate = await importService.importOne('uri://sample');

    expect(duplicate.status, ImportStatus.duplicate);
    expect(duplicate.message, 'hash');

    final receiptsAfter = await db.query('receipts');
    expect(receiptsAfter.length, 1);
    final itemsAfter = await db.query('line_items');
    expect(itemsAfter.length, items.length);
  });

  test('imports JSON receipt when PDF extraction fails', () async {
    final jsonText = await File('assets/sample_receipt.json').readAsString();

    when(() => pdf.fileHash('uri://json'))
        .thenAnswer((_) async => 'json-receipt-hash');
    when(() => pdf.extractTextPages('uri://json'))
        .thenThrow(PdfTextExtractionException('unsupported'));
    when(() => pdf.readTextFile('uri://json'))
        .thenAnswer((_) async => jsonText);

    final result = await importService.importOne('uri://json');

    expect(result.status, ImportStatus.success);
    expect(result.receiptId, isNotEmpty);
  });

  test('imports JSON payload returned from PDF extraction', () async {
    final jsonText = await File('assets/sample_receipt.json').readAsString();

    when(() => pdf.fileHash('uri://embedded-json'))
        .thenAnswer((_) async => 'embedded-json-hash');
    when(() => pdf.extractTextPages('uri://embedded-json'))
        .thenAnswer((_) async => [jsonText]);
    when(() => pdf.pageCount('uri://embedded-json')).thenAnswer((_) async => 1);

    final result = await importService.importOne('uri://embedded-json');

    expect(result.status, ImportStatus.success);
    expect(result.receiptId, isNotEmpty);
  });

  test('imports JSON receipt when extracted PDF pages are empty', () async {
    final jsonText = await File('assets/sample_receipt.json').readAsString();

    when(() => pdf.fileHash('uri://empty-pages-json'))
        .thenAnswer((_) async => 'empty-pages-json-hash');
    when(() => pdf.extractTextPages('uri://empty-pages-json'))
        .thenAnswer((_) async => const []);
    when(() => pdf.readTextFile('uri://empty-pages-json'))
        .thenAnswer((_) async => jsonText);

    final result = await importService.importOne('uri://empty-pages-json');

    expect(result.status, ImportStatus.success);
    expect(result.receiptId, isNotEmpty);
  });

  test('importMany keeps partial success and heuristic duplicate isolated',
      () async {
    final sampleText = await File('assets/sample_receipt.txt').readAsString();

    when(() => pdf.fileHash('uri://batch-first'))
        .thenAnswer((_) async => 'batch-first-hash');
    when(() => pdf.extractTextPages('uri://batch-first'))
        .thenAnswer((_) async => [sampleText]);

    when(() => pdf.fileHash('uri://batch-heuristic-duplicate'))
        .thenAnswer((_) async => 'batch-second-hash');
    when(() => pdf.extractTextPages('uri://batch-heuristic-duplicate'))
        .thenAnswer((_) async => [sampleText]);

    final results = await importService.importMany([
      'uri://batch-first',
      'uri://batch-heuristic-duplicate',
    ]);

    expect(results, hasLength(2));
    expect(results[0].status, ImportStatus.success);
    expect(results[1].status, ImportStatus.duplicate);
    expect(results[1].message, 'heuristic');

    final db = await DatabaseHelper.database;
    expect(await db.query('receipts'), hasLength(1));
    final monthlyTotals = await db.query(
      'monthly_totals',
      where: 'year = ? AND month = ?',
      whereArgs: [2025, 8],
    );
    expect(monthlyTotals, hasLength(1));
    expect(
      (monthlyTotals.first['total'] as num).toDouble(),
      closeTo(23.40, 0.01),
    );
  });

  test('failed import does not persist data and can be retried', () async {
    final sampleText = await File('assets/sample_receipt.txt').readAsString();
    var extractionAttempts = 0;

    when(() => pdf.fileHash('uri://retry'))
        .thenAnswer((_) async => 'retry-hash');
    when(() => pdf.extractTextPages('uri://retry')).thenAnswer((_) async {
      extractionAttempts++;
      if (extractionAttempts == 1) {
        throw StateError('NIP 1234567890 at C:\\private\\receipt.pdf');
      }
      return [sampleText];
    });

    final first = await importService.importOne('uri://retry');
    final db = await DatabaseHelper.database;

    expect(first.status, ImportStatus.error);
    expect(
      first.message,
      'Unexpected error while importing the receipt. Please try again.',
    );
    expect(first.message, isNot(contains('1234567890')));
    expect(first.message, isNot(contains('C:\\private')));
    expect(await db.query('receipts'), isEmpty);
    expect(await db.query('line_items'), isEmpty);

    final second = await importService.importOne('uri://retry');

    expect(second.status, ImportStatus.success);
    expect(second.receiptId, isNotEmpty);
    expect(await db.query('receipts'), hasLength(1));
  });

  test('empty PDF with invalid fallback returns safe message', () async {
    when(() => pdf.fileHash('content://provider/private/empty.pdf'))
        .thenAnswer((_) async => 'empty-invalid-hash');
    when(() => pdf.extractTextPages('content://provider/private/empty.pdf'))
        .thenAnswer((_) async => const []);
    when(() => pdf.readTextFile('content://provider/private/empty.pdf'))
        .thenAnswer((_) async => 'NIP 1234567890 at C:\\private\\bad.txt');

    final result = await importService.importOne(
      'content://provider/private/empty.pdf',
    );

    expect(result.status, ImportStatus.error);
    expect(
      result.message,
      'PDF does not contain any machine-readable text or embedded receipt data.',
    );
    expect(result.message, isNot(contains('content://')));
    expect(result.message, isNot(contains('1234567890')));
    expect(result.message, isNot(contains('C:\\private')));

    final db = await DatabaseHelper.database;
    expect(await db.query('receipts'), isEmpty);
    expect(await db.query('line_items'), isEmpty);
  });

  test('unexpected import errors return a generic safe message', () async {
    when(() => pdf.fileHash('content://provider/private/receipt.pdf'))
        .thenThrow(StateError('NIP 1234567890 at /Users/me/receipt.pdf'));

    final result = await importService.importOne(
      'content://provider/private/receipt.pdf',
    );

    expect(result.status, ImportStatus.error);
    expect(
      result.message,
      'Unexpected error while importing the receipt. Please try again.',
    );
    expect(result.message, isNot(contains('StateError')));
    expect(result.message, isNot(contains('content://')));
    expect(result.message, isNot(contains('/Users/me')));
    expect(result.message, isNot(contains('1234567890')));
  });
}
