import 'package:flutter/widgets.dart';

/// Stable widget keys used by device-level UI automation.
///
/// Keep this list limited to durable user actions and outcome states. Keys are
/// a test contract, not selectors for visual layout.
class AppTestKeys {
  AppTestKeys._();

  static const navHome = ValueKey('nav_home');
  static const navImport = ValueKey('nav_import');
  static const navStats = ValueKey('nav_stats');
  static const navReceipts = ValueKey('nav_receipts');
  static const navSettings = ValueKey('nav_settings');
  static const importButton = ValueKey('import_button');
  static const importStatusSuccess = ValueKey('import_status_success');
  static const importStatusDuplicate = ValueKey('import_status_duplicate');
  static const importStatusError = ValueKey('import_status_error');
  static const receiptList = ValueKey('receipt_list');
  static const onboardingGetStarted = ValueKey('onboarding_get_started');
}
