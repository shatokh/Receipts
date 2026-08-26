import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/app/app_test_keys.dart';

import 'device_test_harness.dart';
import 'waiters.dart';

class ReceiptAppDriver {
  ReceiptAppDriver(this.tester, this.harness);

  final WidgetTester tester;
  final DeviceTestHarness harness;

  Future<void> startAtImport() async {
    await tester.pumpWidget(harness.buildApp());
    await pumpAndSettleSafe(tester);
    await tester.tap(find.byKey(AppTestKeys.onboardingGetStarted));
    await pumpAndSettleSafe(tester);
    await tester.tap(find.byKey(AppTestKeys.navImport));
    await pumpAndSettleSafe(tester);
  }

  Future<void> importQueuedReceiptSuccessfully() async {
    await tester.tap(find.byKey(AppTestKeys.importButton));
    await waitForSuccessfulImport();
  }

  Future<void> waitForSuccessfulImport({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(timeout);
    final successBadge = find.byKey(AppTestKeys.importStatusSuccess);
    final errorBadge = find.byKey(AppTestKeys.importStatusError);
    final importSnackBar = find.byType(SnackBar);

    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (successBadge.evaluate().isNotEmpty) {
        return;
      }
      if (errorBadge.evaluate().isNotEmpty) {
        fail(
          'Import pipeline returned '
          '${harness.errorLogger.lastErrorType ?? 'unknown error'} instead of success.',
        );
      }
      if (importSnackBar.evaluate().isNotEmpty) {
        fail('Import picker failed before reaching the import pipeline.');
      }
    }

    fail('Timed out waiting for a successful import result.');
  }

  Future<void> openReceipts() async {
    await tester.tap(find.byKey(AppTestKeys.navReceipts));
    await waitForFinder(tester, find.byKey(AppTestKeys.receiptList));
  }
}
