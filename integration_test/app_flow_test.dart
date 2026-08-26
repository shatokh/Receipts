import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/app/router.dart';
import 'package:receipts/core/logging/error_log_service.dart';
import 'package:receipts/data/database.dart';
import 'package:receipts/di/test_overrides.dart';
import 'package:receipts/features/receipt_details/widgets/receipt_details_content.dart';
import 'package:receipts/platform/pdf_text_extractor/pdf_text_extractor.dart';

import '../test/test_infra/fakes/fake_file_import_service.dart';
import 'test_keys.dart';

Future<void> pumpAndSettleSafe(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (true) {
    final now = DateTime.now();
    final remaining = deadline.difference(now);

    if (remaining <= Duration.zero) {
      fail('pumpAndSettleSafe timed out after $timeout');
    }

    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        remaining,
      );
      return;
    } on FlutterError catch (error) {
      final message = error.message;
      if (!message.contains('pumpAndSettle timed out')) {
        rethrow;
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

Future<void> waitForSuccessfulImport(
  WidgetTester tester, {
  required String Function() pipelineErrorType,
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  final successBadge = find.byKey(TestKeys.importStatusSuccess);
  final errorBadge = find.byKey(TestKeys.importStatusError);
  final importSnackBar = find.byType(SnackBar);

  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (successBadge.evaluate().isNotEmpty) {
      return;
    }
    if (errorBadge.evaluate().isNotEmpty) {
      fail(
        'Import pipeline returned ${pipelineErrorType()} instead of success.',
      );
    }
    if (importSnackBar.evaluate().isNotEmpty) {
      fail('Import picker failed before reaching the import pipeline.');
    }
  }

  fail('Timed out waiting for a successful import result.');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeFileImportService fakeFileImportService;
  late FakePdfTextExtractor fakePdfTextExtractor;
  late _RecordingErrorLogService errorLogger;
  late List<Override> overrides;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    DatabaseHelper.configureForTesting(
      databaseName: 'integration_test.db',
      useFfi: false,
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    fakeFileImportService = FakeFileImportService();
    fakePdfTextExtractor = FakePdfTextExtractor(fakeFileImportService);
    errorLogger = _RecordingErrorLogService();

    await DatabaseHelper.close();
    final databasesPath = await getDatabasesPath();
    final dbFile = p.join(databasesPath, 'integration_test.db');
    await deleteDatabase(dbFile);
    router.go('/onboarding');

    overrides = await createIntegrationTestOverrides(
      fileImportService: fakeFileImportService,
      pdfTextExtractor: fakePdfTextExtractor,
      additionalOverrides: [
        errorLogServiceProvider.overrideWithValue(errorLogger),
      ],
    );
  });

  tearDown(() async {
    fakeFileImportService.clear();
    await DatabaseHelper.close();
  });

  testWidgets('imports a receipt with native SQLite', (tester) async {
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

    await tester.tap(find.byKey(TestKeys.navImport));
    await pumpAndSettleSafe(tester);

    await tester.tap(find.byKey(TestKeys.importButton));
    await waitForSuccessfulImport(
      tester,
      pipelineErrorType: () => errorLogger.lastErrorType ?? 'unknown error',
    );

    expect(find.byKey(TestKeys.importStatusSuccess), findsOneWidget);
  });

  testWidgets('shows a duplicate result for an existing file hash',
      (tester) async {
    final sampleText = await rootBundle.loadString('assets/sample_receipt.txt');
    final request = FakeImportRequest(
      assetPath: 'assets/test/receipts/sample.pdf',
      uri: 'asset://sample.pdf',
      textPages: [sampleText],
      hash: 'integration-duplicate-hash',
    );
    fakeFileImportService.queueImport([request]);

    await tester.pumpWidget(buildTestApp(overrides: overrides));
    await pumpAndSettleSafe(tester);
    await tester.tap(find.byKey(TestKeys.onboardingGetStarted));
    await pumpAndSettleSafe(tester);
    await tester.tap(find.byKey(TestKeys.navImport));
    await pumpAndSettleSafe(tester);

    await tester.tap(find.byKey(TestKeys.importButton));
    await waitForSuccessfulImport(
      tester,
      pipelineErrorType: () => errorLogger.lastErrorType ?? 'unknown error',
    );

    fakeFileImportService.queueImport([request]);
    await tester.tap(find.byKey(TestKeys.importButton));
    await waitForFinder(tester, find.byKey(TestKeys.importStatusDuplicate));

    expect(find.byKey(TestKeys.importStatusSuccess), findsOneWidget);
    expect(find.byKey(TestKeys.importStatusDuplicate), findsOneWidget);
  });

  testWidgets('imports JSON when PDF text extraction is empty', (tester) async {
    fakeFileImportService.queueImport([
      const FakeImportRequest(
        assetPath: 'assets/sample_receipt.json',
        uri: 'asset://sample_receipt.json',
        textPages: [],
        hash: 'integration-json-fallback-hash',
      ),
    ]);

    await tester.pumpWidget(buildTestApp(overrides: overrides));
    await pumpAndSettleSafe(tester);
    await tester.tap(find.byKey(TestKeys.onboardingGetStarted));
    await pumpAndSettleSafe(tester);
    await tester.tap(find.byKey(TestKeys.navImport));
    await pumpAndSettleSafe(tester);

    await tester.tap(find.byKey(TestKeys.importButton));
    await waitForSuccessfulImport(
      tester,
      pipelineErrorType: () => errorLogger.lastErrorType ?? 'unknown error',
    );

    expect(find.byKey(TestKeys.importStatusSuccess), findsOneWidget);
  });

  testWidgets('opens receipt details after an import', (tester) async {
    final sampleText = await rootBundle.loadString('assets/sample_receipt.txt');
    fakeFileImportService.queueImport([
      FakeImportRequest(
        assetPath: 'assets/test/receipts/sample.pdf',
        uri: 'asset://details.pdf',
        textPages: [sampleText],
        hash: 'integration-details-hash',
      ),
    ]);

    await tester.pumpWidget(buildTestApp(overrides: overrides));
    await pumpAndSettleSafe(tester);
    await tester.tap(find.byKey(TestKeys.onboardingGetStarted));
    await pumpAndSettleSafe(tester);
    await tester.tap(find.byKey(TestKeys.navImport));
    await pumpAndSettleSafe(tester);
    await tester.tap(find.byKey(TestKeys.importButton));
    await waitForSuccessfulImport(
      tester,
      pipelineErrorType: () => errorLogger.lastErrorType ?? 'unknown error',
    );

    await tester.tap(find.byKey(TestKeys.navReceipts));
    await waitForFinder(tester, find.byKey(TestKeys.receiptList));
    await tester.tap(find.textContaining('Biedronka').first);
    await waitForFinder(tester, find.byType(ReceiptDetailsContent));

    expect(find.byType(ReceiptDetailsContent), findsOneWidget);
  });

  testWidgets('keeps imported receipts after an app rebuild', (tester) async {
    final sampleText = await rootBundle.loadString('assets/sample_receipt.txt');
    fakeFileImportService.queueImport([
      FakeImportRequest(
        assetPath: 'assets/test/receipts/sample.pdf',
        uri: 'asset://rebuild.pdf',
        textPages: [sampleText],
        hash: 'integration-rebuild-hash',
      ),
    ]);

    await tester.pumpWidget(buildTestApp(overrides: overrides));
    await pumpAndSettleSafe(tester);
    await tester.tap(find.byKey(TestKeys.onboardingGetStarted));
    await pumpAndSettleSafe(tester);
    await tester.tap(find.byKey(TestKeys.navImport));
    await pumpAndSettleSafe(tester);
    await tester.tap(find.byKey(TestKeys.importButton));
    await waitForSuccessfulImport(
      tester,
      pipelineErrorType: () => errorLogger.lastErrorType ?? 'unknown error',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(buildTestApp(overrides: overrides));
    await pumpAndSettleSafe(tester);
    await tester.tap(find.byKey(TestKeys.navReceipts));
    await waitForFinder(tester, find.byKey(TestKeys.receiptList));

    expect(find.textContaining('Biedronka'), findsWidgets);
  });

  testWidgets('shows an error result when extraction fails', (tester) async {
    final brokenRequest = FakeImportRequest(
      assetPath: 'assets/test/receipts/broken.pdf',
      uri: 'asset://broken.pdf',
      textPages: const [],
      hash: 'integration-broken-hash',
      extractionError:
          PdfTextExtractionException('Unable to read provided PDF'),
    );

    await tester.pumpWidget(buildTestApp(overrides: overrides));
    await pumpAndSettleSafe(tester);

    await tester.tap(find.byKey(TestKeys.onboardingGetStarted));
    await pumpAndSettleSafe(tester);
    await tester.tap(find.byKey(TestKeys.navImport));
    await pumpAndSettleSafe(tester);
    fakeFileImportService.queueImport([brokenRequest]);

    await tester.tap(find.byKey(TestKeys.importButton));
    await waitForFinder(
      tester,
      find.byKey(TestKeys.importStatusError),
      timeout: const Duration(seconds: 20),
    );

    expect(find.byKey(TestKeys.importStatusError), findsOneWidget);
  });
}

class _RecordingErrorLogService extends ErrorLogService {
  _RecordingErrorLogService() : super(enabled: false);

  String? lastErrorType;

  @override
  Future<void> logImportFailure({
    required String safUri,
    required String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? details,
  }) async {
    lastErrorType =
        error == null ? 'unknown error' : error.runtimeType.toString();
  }
}
