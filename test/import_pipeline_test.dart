import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:biedronka_expenses/data/database.dart';
import 'package:biedronka_expenses/data/repositories/analytics_repository.dart';
import 'package:biedronka_expenses/data/repositories/receipt_repository.dart';
import 'package:biedronka_expenses/domain/models/import_result.dart';
import 'package:biedronka_expenses/domain/parsing/receipt_parser.dart';
import 'package:biedronka_expenses/features/import/import_service.dart';
import 'package:biedronka_expenses/platform/pdf_text_extractor/pdf_text_extractor.dart';
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
}
