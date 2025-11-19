import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Чеки';

  @override
  String get navHome => 'Главная';

  @override
  String get navImport => 'Импорт';

  @override
  String get navStats => 'Статистика';

  @override
  String get navReceipts => 'Чеки';

  @override
  String get navSettings => 'Настройки';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get languageTitle => 'Язык';

  @override
  String get chooseLanguage => 'Выберите язык';

  @override
  String get english => 'Английский';

  @override
  String get russian => 'Русский';

  @override
  String get polish => 'Польский';

  @override
  String get aboutLegal => 'Политика и условия';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get termsOfUse => 'Условия использования';

  @override
  String get openInBrowser => 'Открыть в браузере';

  @override
  String get couldNotOpenLink => 'Не удалось открыть ссылку';

  @override
  String get ok => 'ОК';

  @override
  String get cancel => 'Отмена';

  @override
  String get crashReportsTitle => 'Отчёты об ошибках';

  @override
  String get enableSentryCrashReports =>
      'Включить отправку отчётов об ошибках Sentry';

  @override
  String get crashReportsDescription =>
      'Личные данные не отправляются. Изменения применяются сразу.';

  @override
  String get crashReportingEnabled => 'Отчёты об ошибках включены';

  @override
  String get crashReportingDisabled => 'Отчёты об ошибках выключены';

  @override
  String get aboutSectionTitle => 'О приложении';

  @override
  String get aboutAppTitle => 'Receipts — MVP';

  @override
  String get aboutAppDescription =>
      'Приложение Receipts (MVP). Вся обработка на устройстве.';

  @override
  String get versionLabel => 'Версия';

  @override
  String get dataStorageTitle => 'Хранение данных';

  @override
  String get dataStorageDescription =>
      'Все чеки и данные хранятся локально на этом устройстве';

  @override
  String get privacyFirstTitle => 'Приватность прежде всего';

  @override
  String get privacyFirstDescription =>
      'Ваши чеки обрабатываются полностью на вашем устройстве. Данные не отправляются на внешние серверы, кроме необязательных отчётов об ошибках.';

  @override
  String get debugSectionTitle => 'Отладка';

  @override
  String get enableErrorLogging => 'Включить логирование ошибок импорта';

  @override
  String get errorLoggingDescription =>
      'Записывать подробные ошибки импорта в локальный файл (только для разработки).';

  @override
  String errorLogPath(String path) {
    return 'Файл логов: $path';
  }

  @override
  String errorLogEnabled(String path) {
    return 'Логирование включено. Файл: $path';
  }

  @override
  String get clearAllData => 'Удалить все данные';

  @override
  String get clearAllDataDescription =>
      'Удалить все чеки и сбросить приложение';

  @override
  String get clearAllDataDialogTitle => 'Удалить все данные?';

  @override
  String get clearAllDataDialogMessage =>
      'Это действие навсегда удалит все чеки и данные. Его нельзя отменить.';

  @override
  String get clearDataNotImplemented => 'Удаление данных пока не реализовано';

  @override
  String get clearAction => 'Удалить';

  @override
  String get onboardingTitle => 'Обработка только на устройстве';

  @override
  String get onboardingBulletOptimized => 'Оптимизировано для PDF-чеков (MVP)';

  @override
  String get onboardingBulletLocalData =>
      'Все данные остаются на этом устройстве';

  @override
  String get onboardingBulletCrashReports =>
      'Необязательные отчёты об ошибках (их можно отключить в любой момент)';

  @override
  String get onboardingGetStarted => 'Начать работу';

  @override
  String get monthOverviewTitle => 'Обзор месяца';

  @override
  String spendingByCategoryForMonth(Object month) {
    return 'Расходы по категориям — $month';
  }

  @override
  String totalForMonth(Object month) {
    return 'Итого — $month';
  }

  @override
  String get totalLast30Days => 'Итого (30 дн.)';

  @override
  String get averageReceipt => 'Средний чек';

  @override
  String get receiptsMetricLabel => 'Чеки';

  @override
  String get recentReceipts => 'Недавние чеки';

  @override
  String get noReceiptsForMonth => 'За этот месяц ещё нет чеков';

  @override
  String unableToLoadReceipts(Object error) {
    return 'Не удалось загрузить чеки: $error';
  }

  @override
  String showAllReceipts(int count) {
    return 'Показать все чеки ($count)';
  }

  @override
  String get noCategorizedSpending =>
      'За этот месяц ещё нет расходов по категориям';

  @override
  String get categoryFreshProduce => 'Свежие продукты и овощи';

  @override
  String get categoryDairyEggsBakery => 'Молочные продукты, яйца и выпечка';

  @override
  String get categoryPackagedPantry => 'Упакованные продукты и бакалея';

  @override
  String get categoryDrinksSnacks => 'Напитки и снеки';

  @override
  String get categoryHouseholdGoods => 'Товары для дома';

  @override
  String get categoryMisc => 'Разное / Другое';

  @override
  String totalWithAmount(Object amount) {
    return 'Итого — $amount';
  }

  @override
  String unableToLoadCategoriesWithError(Object error) {
    return 'Не удалось загрузить категории: $error';
  }

  @override
  String get unableToLoadCategories => 'Не удалось загрузить категории';

  @override
  String get importReceiptsTitle => 'Импорт чеков';

  @override
  String get importReceiptsButton => 'Импорт чеков (PDF или JSON)';

  @override
  String get filesCopiedInfo =>
      'Файлы копируются в память приложения для надёжного доступа.';

  @override
  String importFailed(Object error) {
    return 'Не удалось импортировать: $error';
  }

  @override
  String get noImportsYet => 'Импортов ещё нет';

  @override
  String get importFirstReceiptPrompt =>
      'Импортируйте первый чек (PDF или JSON)';

  @override
  String get importStatusSuccess => 'Успех';

  @override
  String get importStatusDuplicate => 'Дубликат';

  @override
  String get importStatusError => 'Ошибка';

  @override
  String get ocrInProgressMessage =>
      'Выполняется распознавание текста (OCR). Первый запуск может занять больше времени из-за загрузки моделей.';

  @override
  String get retryOcrButtonLabel => 'Повторить OCR';

  @override
  String get unknownFile => 'Неизвестный файл';

  @override
  String get justNow => 'Только что';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мин назад',
      many: '$count мин назад',
      few: '$count мин назад',
      one: '$count мин назад',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ч назад',
      many: '$count ч назад',
      few: '$count ч назад',
      one: '$count ч назад',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count д назад',
      many: '$count д назад',
      few: '$count д назад',
      one: '$count д назад',
    );
    return '$_temp0';
  }

  @override
  String get receiptsTitle => 'Чеки';

  @override
  String get searchHint => 'Поиск по продавцу или дате';

  @override
  String get monthFilterLabel => 'Месяц';

  @override
  String get allMonths => 'Все месяцы';

  @override
  String totalRangeLabel(int start, int end) {
    return 'Диапазон суммы: PLN $start – PLN $end';
  }

  @override
  String get noReceiptsFound => 'Чеки не найдены';

  @override
  String get adjustSearchFilters => 'Измените запрос или фильтры';

  @override
  String get receiptTitle => 'Чек';

  @override
  String get receiptNotFound => 'Чек не найден';

  @override
  String get backToReceipts => 'Назад к чекам';

  @override
  String get noLineItems => 'Для этого чека нет позиций';

  @override
  String get itemHeader => 'Позиция';

  @override
  String get quantityPriceHeader => 'Кол-во × Цена';

  @override
  String get vatHeader => 'НДС';

  @override
  String get totalHeader => 'Итого';

  @override
  String get vatTotalLabel => 'НДС всего:';

  @override
  String get pdfOpenNotImplemented => 'Открытие PDF пока не реализовано';

  @override
  String get openPdf => 'Открыть PDF';

  @override
  String get recategorizationNotImplemented =>
      'Повторная категоризация пока не реализована';

  @override
  String get recategorize => 'Переклассифицировать';

  @override
  String get dashboardTitle => 'Панель расходов';

  @override
  String get importPdf => 'Импорт PDF';

  @override
  String get selectedMonthLabel => 'Выбранный месяц';

  @override
  String get onDeviceProcessing => 'Все данные обрабатываются на устройстве';

  @override
  String get monthlySpend => 'Месячные расходы';

  @override
  String get noReceiptsThisMonth => 'В этом месяце нет чеков';

  @override
  String receiptMerchantAndDate(Object merchant, Object date) {
    return '$merchant, $date';
  }

  @override
  String receiptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count чеков',
      many: '$count чеков',
      few: '$count чека',
      one: '$count чек',
    );
    return '$_temp0';
  }

  @override
  String maxReceiptForMonth(Object month) {
    return 'Максимальный чек — $month';
  }

  @override
  String get maxReceipt => 'Максимальный чек';

  @override
  String get totalLabel => 'Итого';

  @override
  String get unableToLoadData => 'Не удалось загрузить данные';

  @override
  String get dashboardEmptyTitle => 'Чеков ещё нет';

  @override
  String get dashboardEmptyMessage =>
      'Импортируйте первый чек, чтобы увидеть аналитику';

  @override
  String get dashboardErrorMessage => 'Что-то пошло не так';
}
