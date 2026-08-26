import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:integration_test/integration_test.dart';

import 'package:receipts/features/receipt_details/widgets/receipt_details_content.dart';

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

  testWidgets('opens receipt details after an import', (tester) async {
    final sampleText = await rootBundle.loadString('assets/sample_receipt.txt');
    harness.fileImportService.queueImport([
      FakeImportRequest(
        assetPath: 'assets/test/receipts/sample.pdf',
        uri: 'asset://details.pdf',
        textPages: [sampleText],
        hash: 'integration-details-hash',
      ),
    ]);
    app = ReceiptAppDriver(tester, harness);

    await app.startAtImport();
    await app.importQueuedReceiptSuccessfully();
    await app.openReceipts();
    await tester.tap(find.textContaining('Biedronka').first);
    await waitForFinder(tester, find.byType(ReceiptDetailsContent));

    expect(find.byType(ReceiptDetailsContent), findsOneWidget);
  });

  testWidgets('keeps imported receipts after an app rebuild', (tester) async {
    final sampleText = await rootBundle.loadString('assets/sample_receipt.txt');
    harness.fileImportService.queueImport([
      FakeImportRequest(
        assetPath: 'assets/test/receipts/sample.pdf',
        uri: 'asset://rebuild.pdf',
        textPages: [sampleText],
        hash: 'integration-rebuild-hash',
      ),
    ]);
    app = ReceiptAppDriver(tester, harness);

    await app.startAtImport();
    await app.importQueuedReceiptSuccessfully();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(harness.buildApp());
    await pumpAndSettleSafe(tester);
    await app.openReceipts();

    expect(find.textContaining('Biedronka'), findsWidgets);
  });
}
