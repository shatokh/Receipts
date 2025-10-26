import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get navImport;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get navReceipts;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @aboutLegal.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Terms'**
  String get aboutLegal;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get openInBrowser;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get couldNotOpenLink;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @crashReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Crash reports'**
  String get crashReportsTitle;

  /// No description provided for @enableSentryCrashReports.
  ///
  /// In en, this message translates to:
  /// **'Enable Sentry crash reports'**
  String get enableSentryCrashReports;

  /// No description provided for @crashReportsDescription.
  ///
  /// In en, this message translates to:
  /// **'No personal data is sent. Changes take effect immediately.'**
  String get crashReportsDescription;

  /// No description provided for @crashReportingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Crash reporting enabled'**
  String get crashReportingEnabled;

  /// No description provided for @crashReportingDisabled.
  ///
  /// In en, this message translates to:
  /// **'Crash reporting disabled'**
  String get crashReportingDisabled;

  /// No description provided for @aboutSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSectionTitle;

  /// No description provided for @aboutAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipts — MVP'**
  String get aboutAppTitle;

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'Receipts app (MVP). All processing on device.'**
  String get aboutAppDescription;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionLabel;

  /// No description provided for @dataStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'Data storage'**
  String get dataStorageTitle;

  /// No description provided for @dataStorageDescription.
  ///
  /// In en, this message translates to:
  /// **'All receipts and data are stored locally on this device'**
  String get dataStorageDescription;

  /// No description provided for @privacyFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy First'**
  String get privacyFirstTitle;

  /// No description provided for @privacyFirstDescription.
  ///
  /// In en, this message translates to:
  /// **'Your receipts are processed entirely on your device. No data is sent to external servers except for optional crash reports.'**
  String get privacyFirstDescription;

  /// No description provided for @debugSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debugSectionTitle;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear all data'**
  String get clearAllData;

  /// No description provided for @clearAllDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove all receipts and reset the app'**
  String get clearAllDataDescription;

  /// No description provided for @clearAllDataDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all data?'**
  String get clearAllDataDialogTitle;

  /// No description provided for @clearAllDataDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all receipts and data. This action cannot be undone.'**
  String get clearAllDataDialogMessage;

  /// No description provided for @clearDataNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Data clearing not implemented yet'**
  String get clearDataNotImplemented;

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Local-only processing'**
  String get onboardingTitle;

  /// No description provided for @onboardingBulletOptimized.
  ///
  /// In en, this message translates to:
  /// **'Optimized for PDF receipts (MVP)'**
  String get onboardingBulletOptimized;

  /// No description provided for @onboardingBulletLocalData.
  ///
  /// In en, this message translates to:
  /// **'All data stays on this device'**
  String get onboardingBulletLocalData;

  /// No description provided for @onboardingBulletCrashReports.
  ///
  /// In en, this message translates to:
  /// **'Optional crash reports (you can disable any time)'**
  String get onboardingBulletCrashReports;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @monthOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Month overview'**
  String get monthOverviewTitle;

  /// No description provided for @spendingByCategoryForMonth.
  ///
  /// In en, this message translates to:
  /// **'Spending by category — {month}'**
  String spendingByCategoryForMonth(Object month);

  /// No description provided for @totalForMonth.
  ///
  /// In en, this message translates to:
  /// **'Total — {month}'**
  String totalForMonth(Object month);

  /// No description provided for @totalLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Total (30d)'**
  String get totalLast30Days;

  /// No description provided for @averageReceipt.
  ///
  /// In en, this message translates to:
  /// **'Average receipt'**
  String get averageReceipt;

  /// No description provided for @receiptsMetricLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receiptsMetricLabel;

  /// No description provided for @recentReceipts.
  ///
  /// In en, this message translates to:
  /// **'Recent receipts'**
  String get recentReceipts;

  /// No description provided for @noReceiptsForMonth.
  ///
  /// In en, this message translates to:
  /// **'No receipts recorded for this month yet'**
  String get noReceiptsForMonth;

  /// No description provided for @unableToLoadReceipts.
  ///
  /// In en, this message translates to:
  /// **'Unable to load receipts: {error}'**
  String unableToLoadReceipts(Object error);

  /// No description provided for @showAllReceipts.
  ///
  /// In en, this message translates to:
  /// **'Show all receipts ({count})'**
  String showAllReceipts(int count);

  /// No description provided for @noCategorizedSpending.
  ///
  /// In en, this message translates to:
  /// **'No categorized spending for this month yet'**
  String get noCategorizedSpending;

  /// No description provided for @categoryFreshProduce.
  ///
  /// In en, this message translates to:
  /// **'Fresh Produce & Vegetables'**
  String get categoryFreshProduce;

  /// No description provided for @categoryDairyEggsBakery.
  ///
  /// In en, this message translates to:
  /// **'Dairy, Eggs & Bakery'**
  String get categoryDairyEggsBakery;

  /// No description provided for @categoryPackagedPantry.
  ///
  /// In en, this message translates to:
  /// **'Packaged & Pantry Foods'**
  String get categoryPackagedPantry;

  /// No description provided for @categoryDrinksSnacks.
  ///
  /// In en, this message translates to:
  /// **'Drinks & Snacks'**
  String get categoryDrinksSnacks;

  /// No description provided for @categoryHouseholdGoods.
  ///
  /// In en, this message translates to:
  /// **'Household Goods'**
  String get categoryHouseholdGoods;

  /// No description provided for @categoryMisc.
  ///
  /// In en, this message translates to:
  /// **'Miscellaneous / Other'**
  String get categoryMisc;

  /// No description provided for @totalWithAmount.
  ///
  /// In en, this message translates to:
  /// **'Total — {amount}'**
  String totalWithAmount(Object amount);

  /// No description provided for @unableToLoadCategoriesWithError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load categories: {error}'**
  String unableToLoadCategoriesWithError(Object error);

  /// No description provided for @unableToLoadCategories.
  ///
  /// In en, this message translates to:
  /// **'Unable to load categories'**
  String get unableToLoadCategories;

  /// No description provided for @importReceiptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Import receipts'**
  String get importReceiptsTitle;

  /// No description provided for @importReceiptsButton.
  ///
  /// In en, this message translates to:
  /// **'Import receipts (PDF or JSON)'**
  String get importReceiptsButton;

  /// No description provided for @filesCopiedInfo.
  ///
  /// In en, this message translates to:
  /// **'Files are copied to app storage for reliable access.'**
  String get filesCopiedInfo;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(Object error);

  /// No description provided for @noImportsYet.
  ///
  /// In en, this message translates to:
  /// **'No imports yet'**
  String get noImportsYet;

  /// No description provided for @importFirstReceiptPrompt.
  ///
  /// In en, this message translates to:
  /// **'Import your first receipt (PDF or JSON)'**
  String get importFirstReceiptPrompt;

  /// No description provided for @importStatusSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get importStatusSuccess;

  /// No description provided for @importStatusDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get importStatusDuplicate;

  /// No description provided for @importStatusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get importStatusError;

  /// No description provided for @unknownFile.
  ///
  /// In en, this message translates to:
  /// **'Unknown file'**
  String get unknownFile;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} min ago} other {{count} min ago}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} h ago} other {{count} h ago}}'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} d ago} other {{count} d ago}}'**
  String daysAgo(int count);

  /// No description provided for @receiptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receiptsTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by merchant or date'**
  String get searchHint;

  /// No description provided for @monthFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthFilterLabel;

  /// No description provided for @allMonths.
  ///
  /// In en, this message translates to:
  /// **'All months'**
  String get allMonths;

  /// No description provided for @totalRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Total range: PLN {start} - PLN {end}'**
  String totalRangeLabel(int start, int end);

  /// No description provided for @noReceiptsFound.
  ///
  /// In en, this message translates to:
  /// **'No receipts found'**
  String get noReceiptsFound;

  /// No description provided for @adjustSearchFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get adjustSearchFilters;

  /// No description provided for @receiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// No description provided for @receiptNotFound.
  ///
  /// In en, this message translates to:
  /// **'Receipt not found'**
  String get receiptNotFound;

  /// No description provided for @backToReceipts.
  ///
  /// In en, this message translates to:
  /// **'Back to receipts'**
  String get backToReceipts;

  /// No description provided for @noLineItems.
  ///
  /// In en, this message translates to:
  /// **'No line items were recorded for this receipt'**
  String get noLineItems;

  /// No description provided for @itemHeader.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemHeader;

  /// No description provided for @quantityPriceHeader.
  ///
  /// In en, this message translates to:
  /// **'Qty × Price'**
  String get quantityPriceHeader;

  /// No description provided for @vatHeader.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vatHeader;

  /// No description provided for @totalHeader.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalHeader;

  /// No description provided for @vatTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT total:'**
  String get vatTotalLabel;

  /// No description provided for @pdfOpenNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'PDF opening not implemented yet'**
  String get pdfOpenNotImplemented;

  /// No description provided for @openPdf.
  ///
  /// In en, this message translates to:
  /// **'Open PDF'**
  String get openPdf;

  /// No description provided for @recategorizationNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Re-categorization not implemented yet'**
  String get recategorizationNotImplemented;

  /// No description provided for @recategorize.
  ///
  /// In en, this message translates to:
  /// **'Re-categorize'**
  String get recategorize;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending dashboard'**
  String get dashboardTitle;

  /// No description provided for @importPdf.
  ///
  /// In en, this message translates to:
  /// **'Import PDF'**
  String get importPdf;

  /// No description provided for @selectedMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected month'**
  String get selectedMonthLabel;

  /// No description provided for @onDeviceProcessing.
  ///
  /// In en, this message translates to:
  /// **'All data is processed on device'**
  String get onDeviceProcessing;

  /// No description provided for @monthlySpend.
  ///
  /// In en, this message translates to:
  /// **'Monthly spend'**
  String get monthlySpend;

  /// No description provided for @noReceiptsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No receipts this month'**
  String get noReceiptsThisMonth;

  /// No description provided for @receiptMerchantAndDate.
  ///
  /// In en, this message translates to:
  /// **'{merchant}, {date}'**
  String receiptMerchantAndDate(Object merchant, Object date);

  /// No description provided for @receiptCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 receipt} other {{count} receipts}}'**
  String receiptCount(int count);

  /// No description provided for @maxReceiptForMonth.
  ///
  /// In en, this message translates to:
  /// **'Max receipt — {month}'**
  String maxReceiptForMonth(Object month);

  /// No description provided for @maxReceipt.
  ///
  /// In en, this message translates to:
  /// **'Max receipt'**
  String get maxReceipt;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @unableToLoadData.
  ///
  /// In en, this message translates to:
  /// **'Unable to load data'**
  String get unableToLoadData;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No receipts yet'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Import your first receipt to see analytics'**
  String get dashboardEmptyMessage;

  /// No description provided for @dashboardErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get dashboardErrorMessage;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
