import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:biedronka_expenses/data/database.dart';
import 'package:biedronka_expenses/di/test_overrides.dart';
import 'package:biedronka_expenses/platform/pdf_text_extractor/pdf_text_extractor.dart';

import '../test/test_infra/fakes/fake_file_import_service.dart';
import 'test_keys.dart';

Future<void> pumpAndSettleSafe(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (true) {
    try {
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      return;
    } on FlutterError catch (error) {
      final message = error.message ?? error.toString();
      if (!message.contains('pumpAndSettle timed out')) {
        rethrow;
      }

      if (DateTime.now().isAfter(deadline)) {
        fail('pumpAndSettleSafe timed out after $timeout: $message');
      }
    }
  }
}

Future<void> waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final endTime = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for $finder');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeFileImportService fakeFileImportService;
  late FakePdfTextExtractor fakePdfTextExtractor;
  late List<Override> overrides;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    DatabaseHelper.configureForTesting(databaseName: 'integration_test.db');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeFileImportService = FakeFileImportService();
    fakePdfTextExtractor = FakePdfTextExtractor(fakeFileImportService);

    await DatabaseHelper.close();
    final databasesPath = await getDatabasesPath();
    final dbFile = p.join(databasesPath, 'integration_test.db');
    await deleteDatabase(dbFile);

    overrides = await createIntegrationTestOverrides(
      fileImportService: fakeFileImportService,
      pdfTextExtractor: fakePdfTextExtractor,
    );
  });

  tearDown(() async {
    fakeFileImportService.clear();
    await DatabaseHelper.close();
  });

  testWidgets('import flow updates receipts and statistics', (tester) async {
    final sampleText = await rootBundle.loadString('assets/sample_receipt.txt');

    fakeFileImportService.queueImport([
      FakeImportRequest(
        assetPath: 'assets/test/receipts/sample.pdf',
        uri: 'asset://sample.pdf',
        textPages: [sampleText],
        hash: 'integration-sample-hash',
      ),
    ]);

    await tester.pumpWidget(buildTestApp(overrides: overrides));
    await pumpAndSettleSafe(tester);

    await tester.tap(find.byKey(TestKeys.onboardingGetStarted));
    await pumpAndSettleSafe(tester);

    expect(find.byKey(TestKeys.navHome), findsOneWidget);

    await tester.tap(find.byKey(TestKeys.navStats));
    await pumpAndSettleSafe(tester);
    await tester.tap(find.byKey(TestKeys.navHome));
    await pumpAndSettleSafe(tester);

    await tester.tap(find.byKey(TestKeys.navImport));
    await pumpAndSettleSafe(tester);

    await tester.tap(find.byKey(TestKeys.importButton));
    await pumpAndSettleSafe(tester, timeout: const Duration(seconds: 20));

    expect(find.textContaining('Success'), findsWidgets);

    await tester.tap(find.byKey(TestKeys.navReceipts));
    await pumpAndSettleSafe(tester, timeout: const Duration(seconds: 10));
    await waitForFinder(tester, find.byKey(TestKeys.receiptList));

    expect(find.byKey(TestKeys.receiptList), findsOneWidget);
    expect(find.textContaining('Biedronka'), findsWidgets);

    await tester.tap(find.byKey(TestKeys.navStats));
    await pumpAndSettleSafe(tester, timeout: const Duration(seconds: 10));
    await waitForFinder(tester, find.byKey(TestKeys.chartView));
    expect(find.byKey(TestKeys.chartView), findsOneWidget);

    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpAndSettleSafe(tester);
    expect(find.byKey(TestKeys.chartView), findsOneWidget);

    final brokenRequest = FakeImportRequest(
      assetPath: 'assets/test/receipts/broken.pdf',
      uri: 'asset://broken.pdf',
      textPages: const [],
      hash: 'integration-broken-hash',
      extractionError:
          PdfTextExtractionException('Unable to read provided PDF'),
    );

    await tester.tap(find.byKey(TestKeys.navImport));
    await pumpAndSettleSafe(tester);
    fakeFileImportService.queueImport([brokenRequest]);

    await tester.tap(find.byKey(TestKeys.importButton));
    await pumpAndSettleSafe(tester);

    expect(find.textContaining('Error'), findsWidgets);
  });
}
