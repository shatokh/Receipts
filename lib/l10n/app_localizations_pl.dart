import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Paragony';

  @override
  String get navHome => 'Strona główna';

  @override
  String get navImport => 'Import';

  @override
  String get navStats => 'Statystyki';

  @override
  String get navReceipts => 'Paragony';

  @override
  String get navSettings => 'Ustawienia';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get languageTitle => 'Język';

  @override
  String get chooseLanguage => 'Wybierz język';

  @override
  String get english => 'Angielski';

  @override
  String get russian => 'Rosyjski';

  @override
  String get polish => 'Polski';

  @override
  String get aboutLegal => 'Prywatność i warunki';

  @override
  String get privacyPolicy => 'Polityka prywatności';

  @override
  String get termsOfUse => 'Warunki korzystania';

  @override
  String get openInBrowser => 'Otwórz w przeglądarce';

  @override
  String get couldNotOpenLink => 'Nie udało się otworzyć linku';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Anuluj';

  @override
  String get crashReportsTitle => 'Raporty o awariach';

  @override
  String get enableSentryCrashReports => 'Włącz raporty o awariach Sentry';

  @override
  String get crashReportsDescription =>
      'Żadne dane osobowe nie są wysyłane. Zmiany obowiązują od razu.';

  @override
  String get crashReportingEnabled => 'Raportowanie awarii włączone';

  @override
  String get crashReportingDisabled => 'Raportowanie awarii wyłączone';

  @override
  String get aboutSectionTitle => 'Informacje';

  @override
  String get aboutAppTitle => 'Receipts — MVP';

  @override
  String get aboutAppDescription =>
      'Aplikacja Receipts (MVP). Cała obróbka odbywa się na urządzeniu.';

  @override
  String get versionLabel => 'Wersja';

  @override
  String get dataStorageTitle => 'Przechowywanie danych';

  @override
  String get dataStorageDescription =>
      'Wszystkie paragony i dane są przechowywane lokalnie na tym urządzeniu';

  @override
  String get privacyFirstTitle => 'Prywatność na pierwszym miejscu';

  @override
  String get privacyFirstDescription =>
      'Twoje paragony są przetwarzane wyłącznie na Twoim urządzeniu. Żadne dane nie są wysyłane na zewnętrzne serwery, poza opcjonalnymi raportami o awariach.';

  @override
  String get debugSectionTitle => 'Debugowanie';

  @override
  String get enableErrorLogging => 'Włącz logowanie błędów importu';

  @override
  String get errorLoggingDescription =>
      'Zapisuj szczegółowe błędy importu do lokalnego pliku (tylko w wersji deweloperskiej).';

  @override
  String errorLogPath(String path) {
    return 'Plik logu: $path';
  }

  @override
  String errorLogEnabled(String path) {
    return 'Logowanie włączone. Plik: $path';
  }

  @override
  String get clearAllData => 'Wyczyść wszystkie dane';

  @override
  String get clearAllDataDescription =>
      'Usuń wszystkie paragony i zresetuj aplikację';

  @override
  String get clearAllDataDialogTitle => 'Wyczyścić wszystkie dane?';

  @override
  String get clearAllDataDialogMessage =>
      'Spowoduje to trwałe usunięcie wszystkich paragonów i danych. Tej akcji nie można cofnąć.';

  @override
  String get clearDataNotImplemented =>
      'Czyszczenie danych nie jest jeszcze dostępne';

  @override
  String get clearAction => 'Wyczyść';

  @override
  String get onboardingTitle => 'Przetwarzanie tylko lokalne';

  @override
  String get onboardingBulletOptimized =>
      'Zoptymalizowane pod paragony PDF (MVP)';

  @override
  String get onboardingBulletLocalData =>
      'Wszystkie dane pozostają na tym urządzeniu';

  @override
  String get onboardingBulletCrashReports =>
      'Opcjonalne raporty o awariach (możesz wyłączyć w każdej chwili)';

  @override
  String get onboardingGetStarted => 'Zacznij';

  @override
  String get monthOverviewTitle => 'Przegląd miesiąca';

  @override
  String spendingByCategoryForMonth(Object month) {
    return 'Wydatki według kategorii — $month';
  }

  @override
  String totalForMonth(Object month) {
    return 'Suma — $month';
  }

  @override
  String get totalLast30Days => 'Suma (30 dni)';

  @override
  String get averageReceipt => 'Średni paragon';

  @override
  String get receiptsMetricLabel => 'Paragony';

  @override
  String get recentReceipts => 'Ostatnie paragony';

  @override
  String get noReceiptsForMonth => 'Brak paragonów zapisanych w tym miesiącu';

  @override
  String unableToLoadReceipts(Object error) {
    return 'Nie można wczytać paragonów: $error';
  }

  @override
  String showAllReceipts(int count) {
    return 'Pokaż wszystkie paragony ($count)';
  }

  @override
  String get noCategorizedSpending =>
      'Brak wydatków z kategoriami w tym miesiącu';

  @override
  String get categoryFreshProduce => 'Świeże produkty i warzywa';

  @override
  String get categoryDairyEggsBakery => 'Nabiał, jajka i pieczywo';

  @override
  String get categoryPackagedPantry => 'Produkty pakowane i spiżarniane';

  @override
  String get categoryDrinksSnacks => 'Napoje i przekąski';

  @override
  String get categoryHouseholdGoods => 'Artykuły gospodarstwa domowego';

  @override
  String get categoryMisc => 'Różne / inne';

  @override
  String totalWithAmount(Object amount) {
    return 'Suma — $amount';
  }

  @override
  String unableToLoadCategoriesWithError(Object error) {
    return 'Nie można wczytać kategorii: $error';
  }

  @override
  String get unableToLoadCategories => 'Nie można wczytać kategorii';

  @override
  String get importReceiptsTitle => 'Import paragonów';

  @override
  String get importReceiptsButton => 'Importuj paragony (PDF lub JSON)';

  @override
  String get filesCopiedInfo =>
      'Pliki są kopiowane do pamięci aplikacji dla niezawodnego dostępu.';

  @override
  String importFailed(Object error) {
    return 'Import nie powiódł się: $error';
  }

  @override
  String get noImportsYet => 'Brak importów';

  @override
  String get importFirstReceiptPrompt =>
      'Zaimportuj swój pierwszy paragon (PDF lub JSON)';

  @override
  String get importStatusSuccess => 'Sukces';

  @override
  String get importStatusDuplicate => 'Duplikat';

  @override
  String get importStatusError => 'Błąd';

  @override
  String get ocrInProgressMessage =>
      'Trwa rozpoznawanie tekstu (OCR). Pierwsze uruchomienie może potrwać dłużej podczas pobierania modeli.';

  @override
  String get retryOcrButtonLabel => 'Ponów OCR';

  @override
  String get unknownFile => 'Nieznany plik';

  @override
  String get justNow => 'Przed chwilą';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      one: '$count min temu',
      few: '$count min temu',
      many: '$count min temu',
      other: '$count min temu',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      one: '$count godz. temu',
      few: '$count godz. temu',
      many: '$count godz. temu',
      other: '$count godz. temu',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      one: '$count dzień temu',
      few: '$count dni temu',
      many: '$count dni temu',
      other: '$count dni temu',
    );
    return '$_temp0';
  }

  @override
  String get receiptsTitle => 'Paragony';

  @override
  String get searchHint => 'Szukaj po sklepie lub dacie';

  @override
  String get monthFilterLabel => 'Miesiąc';

  @override
  String get allMonths => 'Wszystkie miesiące';

  @override
  String totalRangeLabel(int start, int end) {
    return 'Zakres sumy: PLN $start – PLN $end';
  }

  @override
  String get noReceiptsFound => 'Nie znaleziono paragonów';

  @override
  String get adjustSearchFilters => 'Spróbuj zmienić wyszukiwanie lub filtry';

  @override
  String get receiptTitle => 'Paragon';

  @override
  String get receiptNotFound => 'Nie znaleziono paragonu';

  @override
  String get backToReceipts => 'Wróć do paragonów';

  @override
  String get noLineItems => 'Dla tego paragonu nie zapisano pozycji';

  @override
  String get itemHeader => 'Pozycja';

  @override
  String get quantityPriceHeader => 'Ilość × Cena';

  @override
  String get vatHeader => 'VAT';

  @override
  String get totalHeader => 'Suma';

  @override
  String get vatTotalLabel => 'Suma VAT:';

  @override
  String get pdfOpenNotImplemented =>
      'Otwieranie PDF nie jest jeszcze dostępne';

  @override
  String get openPdf => 'Otwórz PDF';

  @override
  String get recategorizationNotImplemented =>
      'Ponowna kategoryzacja nie jest jeszcze dostępna';

  @override
  String get recategorize => 'Zmień kategorię';

  @override
  String get dashboardTitle => 'Panel wydatków';

  @override
  String get importPdf => 'Importuj PDF';

  @override
  String get selectedMonthLabel => 'Wybrany miesiąc';

  @override
  String get onDeviceProcessing =>
      'Wszystkie dane są przetwarzane na urządzeniu';

  @override
  String get monthlySpend => 'Wydatki miesięczne';

  @override
  String get noReceiptsThisMonth => 'Brak paragonów w tym miesiącu';

  @override
  String receiptMerchantAndDate(Object merchant, Object date) {
    return '$merchant, $date';
  }

  @override
  String receiptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      one: '$count paragon',
      few: '$count paragony',
      many: '$count paragonów',
      other: '$count paragonu',
    );
    return '$_temp0';
  }

  @override
  String maxReceiptForMonth(Object month) {
    return 'Największy paragon — $month';
  }

  @override
  String get maxReceipt => 'Największy paragon';

  @override
  String get totalLabel => 'Suma';

  @override
  String get unableToLoadData => 'Nie można wczytać danych';

  @override
  String get dashboardEmptyTitle => 'Brak paragonów';

  @override
  String get dashboardEmptyMessage =>
      'Zaimportuj pierwszy paragon, aby zobaczyć analizy';

  @override
  String get dashboardErrorMessage => 'Coś poszło nie tak';
}
