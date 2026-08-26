import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:receipts/app/app_test_keys.dart';
import 'package:receipts/platform/pdf_text_extractor/pdf_text_extractor.dart';

import '../test/test_infra/fakes/fake_file_import_service.dart';
import 'support/app_driver.dart';
import 'support/device_test_harness.dart';
import 'support/waiters.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late DeviceTestHarness harness;
  late ReceiptAppDriver app;

  setUpAll(DeviceTestHarness.configureForAndroid);

  setUp(() async {
    harness = await DeviceTestHarness.create();
  });

  tearDown(() => harness.dispose());

  testWidgets('imports a receipt with native SQLite', (tester) async {
    final sampleText = await rootBundle.loadString('assets/sample_receipt.txt');
    harness.fileImportService.queueImport([
      FakeImportRequest(
        assetPath: 'assets/test/receipts/sample.pdf',
        uri: 'asset://sample.pdf',
        textPages: [sampleText],
        hash: 'integration-sample-hash',
      ),
    ]);
    app = ReceiptAppDriver(tester, harness);

    await app.startAtImport();
    await app.importQueuedReceiptSuccessfully();

    expect(find.byKey(AppTestKeys.importStatusSuccess), findsOneWidget);
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
    harness.fileImportService.queueImport([request]);
    app = ReceiptAppDriver(tester, harness);

    await app.startAtImport();
    await app.importQueuedReceiptSuccessfully();

    harness.fileImportService.queueImport([request]);
    await tester.tap(find.byKey(AppTestKeys.importButton));
    await waitForFinder(tester, find.byKey(AppTestKeys.importStatusDuplicate));

    expect(find.byKey(AppTestKeys.importStatusSuccess), findsOneWidget);
    expect(find.byKey(AppTestKeys.importStatusDuplicate), findsOneWidget);
  });

  testWidgets('imports JSON when PDF text extraction is empty', (tester) async {
    harness.fileImportService.queueImport([
      const FakeImportRequest(
        assetPath: 'assets/sample_receipt.json',
        uri: 'asset://sample_receipt.json',
        textPages: [],
        hash: 'integration-json-fallback-hash',
      ),
    ]);
    app = ReceiptAppDriver(tester, harness);

    await app.startAtImport();
    await app.importQueuedReceiptSuccessfully();

    expect(find.byKey(AppTestKeys.importStatusSuccess), findsOneWidget);
  });

  testWidgets('shows a safe error result when extraction fails', (tester) async {
    final brokenRequest = FakeImportRequest(
      assetPath: 'assets/test/receipts/broken.pdf',
      uri: 'asset://broken.pdf',
      textPages: const [],
      hash: 'integration-broken-hash',
      extractionError:
          PdfTextExtractionException('Unable to read provided PDF'),
    );
    harness.fileImportService.queueImport([brokenRequest]);
    app = ReceiptAppDriver(tester, harness);

    await app.startAtImport();
    await tester.tap(find.byKey(AppTestKeys.importButton));
    await waitForFinder(
      tester,
      find.byKey(AppTestKeys.importStatusError),
      timeout: const Duration(seconds: 20),
    );

    expect(find.byKey(AppTestKeys.importStatusError), findsOneWidget);
  });
}
