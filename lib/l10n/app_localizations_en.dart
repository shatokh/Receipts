import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Receipts';

  @override
  String get navHome => 'Home';

  @override
  String get navImport => 'Import';

  @override
  String get navStats => 'Stats';

  @override
  String get navReceipts => 'Receipts';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageTitle => 'Language';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get english => 'English';

  @override
  String get russian => 'Russian';

  @override
  String get polish => 'Polish';

  @override
  String get aboutLegal => 'Privacy & Terms';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get couldNotOpenLink => 'Could not open link';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get crashReportsTitle => 'Crash reports';

  @override
  String get enableSentryCrashReports => 'Enable Sentry crash reports';

  @override
  String get crashReportsDescription =>
      'No personal data is sent. Changes take effect immediately.';

  @override
  String get crashReportingEnabled => 'Crash reporting enabled';

  @override
  String get crashReportingDisabled => 'Crash reporting disabled';

  @override
  String get aboutSectionTitle => 'About';

  @override
  String get aboutAppTitle => 'Receipts — MVP';

  @override
  String get aboutAppDescription =>
      'Receipts app (MVP). All processing on device.';

  @override
  String get versionLabel => 'Version';

  @override
  String get dataStorageTitle => 'Data storage';

  @override
  String get dataStorageDescription =>
      'All receipts and data are stored locally on this device';

  @override
  String get privacyFirstTitle => 'Privacy First';

  @override
  String get privacyFirstDescription =>
      'Your receipts are processed entirely on your device. No data is sent to external servers except for optional crash reports.';

  @override
  String get debugSectionTitle => 'Debug';

  @override
  String get clearAllData => 'Clear all data';

  @override
  String get clearAllDataDescription => 'Remove all receipts and reset the app';

  @override
  String get clearAllDataDialogTitle => 'Clear all data?';

  @override
  String get clearAllDataDialogMessage =>
      'This will permanently delete all receipts and data. This action cannot be undone.';

  @override
  String get clearDataNotImplemented => 'Data clearing not implemented yet';

  @override
  String get clearAction => 'Clear';

  @override
  String get onboardingTitle => 'Local-only processing';

  @override
  String get onboardingBulletOptimized => 'Optimized for PDF receipts (MVP)';

  @override
  String get onboardingBulletLocalData => 'All data stays on this device';

  @override
  String get onboardingBulletCrashReports =>
      'Optional crash reports (you can disable any time)';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get monthOverviewTitle => 'Month overview';

  @override
  String spendingByCategoryForMonth(Object month) {
    return 'Spending by category — $month';
  }

  @override
  String totalForMonth(Object month) {
    return 'Total — $month';
  }

  @override
  String get totalLast30Days => 'Total (30d)';

  @override
  String get averageReceipt => 'Average receipt';

  @override
  String get receiptsMetricLabel => 'Receipts';

  @override
  String get recentReceipts => 'Recent receipts';

  @override
  String get noReceiptsForMonth => 'No receipts recorded for this month yet';

  @override
  String unableToLoadReceipts(Object error) {
    return 'Unable to load receipts: $error';
  }

  @override
  String showAllReceipts(int count) {
    return 'Show all receipts ($count)';
  }

  @override
  String get noCategorizedSpending =>
      'No categorized spending for this month yet';

  @override
  String get categoryFreshProduce => 'Fresh Produce & Vegetables';

  @override
  String get categoryDairyEggsBakery => 'Dairy, Eggs & Bakery';

  @override
  String get categoryPackagedPantry => 'Packaged & Pantry Foods';

  @override
  String get categoryDrinksSnacks => 'Drinks & Snacks';

  @override
  String get categoryHouseholdGoods => 'Household Goods';

  @override
  String get categoryMisc => 'Miscellaneous / Other';

  @override
  String totalWithAmount(Object amount) {
    return 'Total — $amount';
  }

  @override
  String unableToLoadCategoriesWithError(Object error) {
    return 'Unable to load categories: $error';
  }

  @override
  String get unableToLoadCategories => 'Unable to load categories';

  @override
  String get importReceiptsTitle => 'Import receipts';

  @override
  String get importReceiptsButton => 'Import receipts (PDF or JSON)';

  @override
  String get filesCopiedInfo =>
      'Files are copied to app storage for reliable access.';

  @override
  String importFailed(Object error) {
    return 'Import failed: $error';
  }

  @override
  String get noImportsYet => 'No imports yet';

  @override
  String get importFirstReceiptPrompt =>
      'Import your first receipt (PDF or JSON)';

  @override
  String get importStatusSuccess => 'Success';

  @override
  String get importStatusDuplicate => 'Duplicate';

  @override
  String get importStatusError => 'Error';

  @override
  String get unknownFile => 'Unknown file';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
      one: '$count min ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count h ago',
      one: '$count h ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count d ago',
      one: '$count d ago',
    );
    return '$_temp0';
  }

  @override
  String get receiptsTitle => 'Receipts';

  @override
  String get searchHint => 'Search by merchant or date';

  @override
  String get monthFilterLabel => 'Month';

  @override
  String get allMonths => 'All months';

  @override
  String totalRangeLabel(int start, int end) {
    return 'Total range: PLN $start - PLN $end';
  }

  @override
  String get noReceiptsFound => 'No receipts found';

  @override
  String get adjustSearchFilters => 'Try adjusting your search or filters';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String get receiptNotFound => 'Receipt not found';

  @override
  String get backToReceipts => 'Back to receipts';

  @override
  String get noLineItems => 'No line items were recorded for this receipt';

  @override
  String get itemHeader => 'Item';

  @override
  String get quantityPriceHeader => 'Qty × Price';

  @override
  String get vatHeader => 'VAT';

  @override
  String get totalHeader => 'Total';

  @override
  String get vatTotalLabel => 'VAT total:';

  @override
  String get pdfOpenNotImplemented => 'PDF opening not implemented yet';

  @override
  String get openPdf => 'Open PDF';

  @override
  String get recategorizationNotImplemented =>
      'Re-categorization not implemented yet';

  @override
  String get recategorize => 'Re-categorize';

  @override
  String get dashboardTitle => 'Spending dashboard';

  @override
  String get importPdf => 'Import PDF';

  @override
  String get selectedMonthLabel => 'Selected month';

  @override
  String get onDeviceProcessing => 'All data is processed on device';

  @override
  String get monthlySpend => 'Monthly spend';

  @override
  String get noReceiptsThisMonth => 'No receipts this month';

  @override
  String receiptMerchantAndDate(Object merchant, Object date) {
    return '$merchant, $date';
  }

  @override
  String receiptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count receipts',
      one: '1 receipt',
    );
    return '$_temp0';
  }

  @override
  String maxReceiptForMonth(Object month) {
    return 'Max receipt — $month';
  }

  @override
  String get maxReceipt => 'Max receipt';

  @override
  String get totalLabel => 'Total';

  @override
  String get unableToLoadData => 'Unable to load data';

  @override
  String get dashboardEmptyTitle => 'No receipts yet';

  @override
  String get dashboardEmptyMessage =>
      'Import your first receipt to see analytics';

  @override
  String get dashboardErrorMessage => 'Something went wrong';
}
