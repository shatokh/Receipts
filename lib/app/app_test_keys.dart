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

/// Stable, non-visible Semantics identifiers for external device automation.
///
/// Unlike [AppTestKeys], these values are exposed through Android accessibility
/// and can be selected by black-box tools such as Maestro. Keep this list to
/// durable user actions that have an approved device-E2E scenario.
class AppTestSemanticsIds {
  AppTestSemanticsIds._();

  static const onboardingGetStarted = 'onboarding_get_started';
  static const navImport = 'nav_import';
  static const importButton = 'import_button';
  static const importStatusSuccess = 'import_status_success';
  static const importStatusDuplicate = 'import_status_duplicate';
  static const navMonth = 'nav_month';
  static const navReceipts = 'nav_receipts';
  static const receiptsList = 'receipts_list';
  static const monthReceipts = 'month_receipts';
  static const monthPicker = 'month_picker';
  static const monthOption0 = 'month_option_0';
  static const monthOption1 = 'month_option_1';
  static const monthSingleReceipt = 'month_single_receipt';
  static const receiptsFirstItem = 'receipts_first_item';
  static const receiptDetails = 'receipt_details';
  static const receiptOpenPdf = 'receipt_open_pdf';
}
