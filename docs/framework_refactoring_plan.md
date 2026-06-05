# Receipts Framework Refactoring Plan

## 1. Цель документа

Этот документ описывает план рефакторинга внутреннего фреймворка проекта Receipts: архитектурных слоёв, зависимостей, data access, import pipeline, state management, локализации, тестовой инфраструктуры и observability.

Под "фреймворком" здесь понимается не Flutter SDK, а набор внутренних проектных соглашений и базовых модулей, на которых строятся фичи приложения.

## 2. Текущий контекст

Receipts уже имеет рабочую feature-based структуру:

- `lib/app/` - роутинг, глобальные providers, app scaffold.
- `lib/core/` - кросс-функциональные сервисы, сейчас в основном localization/logging.
- `lib/data/` - SQLite helper, repositories, database watch/update bus, aggregate updater.
- `lib/domain/` - модели, parser, категории.
- `lib/features/` - UI и feature controllers.
- `lib/platform/` - platform-specific реализации, сейчас PDF text extractor.
- `test/` и `integration_test/` - unit/import/l10n/integration coverage.

Сильные стороны текущей базы:

- Core flow уже offline-first.
- Platform code отделён интерфейсом `PdfTextExtractor`.
- Есть `DatabaseUpdateBus`, `watchDatabase`, `MonthDateRange`, `AggregatesUpdater`.
- Есть тестовый harness для изолированной sqflite/Riverpod среды.
- Есть EN/RU/PL локализация.
- Import pipeline уже покрывает PDF text и JSON fallback.

Основные зоны для рефакторинга:

- `lib/app/providers.dart` стал центральным местом для слишком разных зависимостей и UI-derived providers.
- Repositories одновременно отвечают за SQL, aggregate updates, watch lifecycle и частично use-case поведение.
- Domain layer содержит модели и parser, но нет явного application/use-case слоя.
- Import pipeline держит orchestration внутри feature service.
- UI файлы местами крупные и совмещают layout, formatting, state mapping и actions.
- Generated l10n файлы лежат рядом с ARB, что требует чётких правил генерации.
- Error logging и import telemetry уже принимают `safUri`, `error`, `stackTrace` и `details`; privacy/logging hardening нужно делать до крупных переносов import/use-case кода.
- В проекте фактически есть EN/RU/PL локализация, поэтому любые l10n правила должны учитывать все три ARB/generated locale файла.

## 3. Цели рефакторинга

1. Сделать архитектуру предсказуемой для будущих фич.
2. Уменьшить связность между UI, repositories, platform services и import orchestration.
3. Вынести повторяемые framework-паттерны в небольшие базовые модули.
4. Сохранить offline-first и privacy-first свойства.
5. Упростить тестирование use cases без Flutter UI.
6. Снизить риск регрессий в database aggregates и import pipeline.
7. Подготовить основу для будущих возможностей: bulk import, recategorization, PDF open, clear data, OCR/sync только если они будут явно нужны.

## 4. Non-goals

На этом этапе не планируется:

- Переписывать приложение на другую архитектуру или state management.
- Вводить code generation ради code generation.
- Переносить SQLite на Drift/Isar/Hive без отдельного решения.
- Добавлять backend, sync, cloud backup или analytics.
- Переписывать все экраны сразу.
- Удалять существующие тесты или менять UX без продуктовой причины.

## 5. Целевая архитектура

Предлагаемая структура после рефакторинга:

```text
lib/
├── app/
│   ├── router.dart
│   ├── main_scaffold.dart
│   └── app_providers.dart
├── core/
│   ├── formatting/
│   ├── localization/
│   ├── logging/
│   ├── privacy/
│   └── result/
├── data/
│   ├── database/
│   │   ├── database_helper.dart
│   │   ├── migrations.dart
│   │   ├── schema.dart
│   │   └── month_date_range.dart
│   ├── repositories/
│   └── watch/
├── domain/
│   ├── models/
│   ├── parsing/
│   ├── categories/
│   └── value_objects/
├── application/
│   ├── import/
│   ├── receipts/
│   ├── analytics/
│   └── settings/
├── features/
│   └── ...
├── platform/
│   └── ...
└── l10n/
```

Это не обязательная одномоментная миграция. Структуру нужно вводить постепенно, начиная с модулей с наибольшим риском изменений.

## 6. Архитектурные правила после рефакторинга

### 6.1. Dependency direction

Разрешённые зависимости:

- `features` -> `application`, `domain`, `core`, `app providers`
- `application` -> `domain`, repository interfaces/services
- `data` -> `domain`, `core`
- `platform` -> service interfaces/contracts
- `domain` -> только Dart/core primitives и чистые helpers

Запрещённые зависимости:

- `domain` -> Flutter widgets, Riverpod, sqflite, platform channels
- `data` -> feature widgets/controllers
- `application` -> concrete UI
- `platform` -> feature-specific UI state

Переходное правило:

- Сейчас repository interfaces/ports не выделены: providers создают concrete repositories напрямую. Перед этапом `application/` нужно явно выбрать один из двух вариантов:
  - временно разрешить `application` зависеть от concrete `data` repositories и зафиксировать это как переходный компромисс;
  - сначала выделить repository contracts/ports, а уже потом переносить use cases.

### 6.2. Provider ownership

`lib/app/providers.dart` нужно разделить:

- `app_providers.dart` - композиция runtime dependencies.
- `repository_providers.dart` - repositories.
- `service_providers.dart` - application services/use cases.
- `ui_state_providers.dart` - shared UI filters such as selected month/search/filter state.

Feature-local state должен жить рядом с feature, если он не используется несколькими разделами.

Provider split должен быть механическим PR без изменения behavior:

- public provider names сохраняются;
- `lib/app/providers.dart` остаётся backward-compatible barrel/facade;
- shared runtime providers выносятся в `lib/app/providers/*`;
- feature-local UI state постепенно переносится ближе к feature, например receipt filters в receipts feature;
- Flutter-only UI types вроде `RangeValues` не должны становиться частью application/domain contracts.

### 6.3. Application/use-case layer

Слой `application/` должен принять orchestration:

- import receipt(s)
- delete/clear receipt data только если это уже реализуемая feature, а не часть чистого refactor PR
- update category
- rebuild aggregates
- load dashboard/month view models
- read/update settings

Repositories должны отвечать за persistence operations, но не за сценарии приложения.

Aggregate ownership нужно решить до переноса import orchestration:

- либо repositories временно продолжают обновлять `monthly_totals`, `category_month_totals` и слать `DatabaseUpdateBus`;
- либо use cases становятся единственным владельцем aggregate rebuild/update и update bus notification.

Нельзя оставлять смешанную модель, где одни write paths обновляют aggregates в repositories, а другие в use cases: это создаст риск двойных пересчётов или пропущенных уведомлений.

## 7. План по этапам

## Этап 0. Baseline, guardrails и минимальное покрытие

Цель: зафиксировать текущее состояние, закрыть самые опасные privacy/logging риски и добавить минимальное поведенческое покрытие вокруг behavior, которое нельзя сломать незаметно.

Почему это нужно:

- Сейчас тесты покрывают import pipeline, несколько parser cases и часть l10n.
- Почти нет прямого покрытия repositories, aggregate updater, database watchers, settings/logging, provider composition и UI state filters.
- Рефакторинг будет переносить код между слоями; без behavioral tests легко получить "зелёную компиляцию", но сломать агрегаты, watch updates, duplicate detection или privacy-инварианты.
- Privacy/logging риск уже существует в текущем коде, поэтому sanitization нельзя откладывать до поздних этапов.

Базовый порядок:

1. Снять текущий baseline:
   - `flutter analyze`
   - `flutter test`
   - `dart run tool/test_with_coverage.dart --min-coverage=0`
   - сохранить процент coverage и список файлов с низким покрытием из `coverage/lcov.info`
   - зафиксировать известные failing tests/analyzer warnings, если они есть
2. Добавить privacy/logging guardrails:
   - убрать raw `safUri` из local logs/import telemetry
   - не писать raw parser payload, receipt content, file paths, NIP, line items, totals
   - ограничить `error`, `stackTrace` и `details` allowlist/sanitizer-слоем
3. Добавить тесты на самые рискованные behavior contracts.
4. Поднять coverage gate постепенно:
   - сначала зафиксировать текущий baseline
   - затем поднять минимум на 5-10 процентных пунктов
   - не гнаться за 100%, а покрывать критичные сценарии
5. Только после этого начинать этапы provider/database/use-case refactor.

Приоритеты покрытия:

### P0. Import pipeline regression tests

Добавить/проверить сценарии:

- PDF без machine-readable text возвращает безопасную ошибку.
- Empty extracted pages и whitespace-only text.
- Unsupported text fallback не раскрывает raw payload.
- Heuristic duplicate: тот же merchant/date/total, другой hash.
- JSON fallback failure: invalid JSON, unsupported text file.
- Aggregates обновляются только после success, а duplicate/error не меняют БД.
- Error logging disabled не пишет логов; enabled пишет только safe fields.

Файлы:

- `test/import_pipeline_test.dart`
- новые fakes в `test/test_infra/fakes/`

### P0. Repository and aggregate tests

Добавить прямые тесты для:

- `ReceiptRepository.insertReceiptWithItems`
- `ReceiptRepository.updateReceipt` с переносом чека в другой месяц
- `ReceiptRepository.deleteReceipt`
- `ReceiptRepository.insertLineItems`
- `AnalyticsRepository.getMonthOverview`
- `AnalyticsRepository.watchLast12MonthsTotals`
- `AggregatesUpdater.updateForMonths`
- `AggregatesUpdater.rebuildAll`

Проверять:

- `monthly_totals`
- `category_month_totals`
- `DatabaseUpdateBus` emits после writes
- старый месяц пересчитывается при update/delete
- legacy category ids нормализуются

Предлагаемые файлы:

- `test/data/receipt_repository_test.dart`
- `test/data/analytics_repository_test.dart`
- `test/data/aggregates_updater_test.dart`
- `test/data/database_watch_test.dart`

### P0. Date/month helper tests

Добавить тесты для `MonthDateRange`:

- середина месяца
- декабрь -> январь следующего года
- leap year February
- `forYearMonth`

Файл:

- `test/data/month_date_range_test.dart`

### P1. Parser contract tests

Расширить parser coverage:

- unsupported source throws `FormatException`
- missing purchase date
- missing total
- VAT summary fallback
- discount/storno JSON behavior
- merchant detection by TIN/company name
- decimal comma and negative amounts

Файл:

- `test/domain/receipt_parser_test.dart` или расширить текущий `test/receipt_parser_new_format_test.dart`

### P0. Privacy, settings and logging tests

Добавить тесты:

- `SettingsRepository` default values.
- `setSentryEnabled` persists.
- `setDevLoggingEnabled` persists.
- `ErrorLogService(enabled: false)` no-op.
- `ErrorLogService(enabled: true)` writes JSONL with allowed fields only.
- Import telemetry/logging не пишет raw `safUri`, raw payload, receipt text, file paths, NIP, line items, totals.
- Unexpected errors возвращают user-safe message без `error.toString()` с потенциально чувствительными деталями.

Для `ErrorLogService` желательно сначала ввести injectable log directory/file resolver, чтобы тест не зависел от real app documents directory.

Предлагаемые файлы:

- `test/data/settings_repository_test.dart`
- `test/core/error_log_service_test.dart`

### P1. Provider composition smoke tests

Добавить тесты, которые создают `ProviderContainer` с runtime overrides и проверяют:

- `importServiceProvider` собирается с fake PDF extractor/settings/logger.
- `sentryEnabledProvider` пишет в fake settings repository.
- `devLoggingEnabledProvider` переключает `errorLogServiceProvider.enabled`.
- `filteredReceiptsProvider` фильтрует по query/month/amount.

Файл:

- `test/app/providers_test.dart`

### P2. Widget smoke tests

Перед UI split добавить минимальные widget tests:

- Dashboard empty state.
- Month empty state.
- Receipts filters render.
- Import screen empty state and import button action with fake file service.
- Settings toggles render and call notifiers.

Не пытаться покрыть весь layout; цель - зафиксировать основные states и navigation/actions.

Предлагаемые файлы:

- `test/features/dashboard/dashboard_view_test.dart`
- `test/features/month/month_view_test.dart`
- `test/features/receipts/receipts_view_test.dart`
- `test/features/import/import_view_test.dart`
- `test/features/settings/settings_view_test.dart`

### P2. Integration smoke

Сохранить один небольшой happy-path integration flow:

- onboarding -> dashboard
- import sample
- receipt appears
- details opens
- settings/language page opens

Не добавлять много flaky UI integration tests до стабилизации harness.

Coverage acceptance before structural refactor:

- Минимум перед provider split: baseline снят, privacy/logging guardrails добавлены, самые рискованные P0 import/privacy tests проходят.
- Минимум перед database/use-case refactor: P0 repository/aggregate/month helper tests добавлены и проходят.
- Желательно: coverage gate поднят до уровня, который реально проходит в CI.
- Практичная долгосрочная цель: 70-75% line coverage, если текущий baseline ниже. Это ориентир, а не блокер первого механического provider split PR.
- Практичная цель перед UI split: хотя бы smoke widget tests для экранов, которые будут дробиться.

Команды:

```powershell
flutter test
dart run tool/test_with_coverage.dart --min-coverage=0
dart run tool/test_with_coverage.dart --min-coverage=75
```

Критерии готовности:

- Есть coverage baseline.
- Privacy/logging guardrails не допускают raw receipt/file/user data в developer logs, local logs и telemetry.
- P0 behavior tests проходят.
- Coverage gate настроен на достижимый минимум.
- Known gaps перечислены явно, а не скрыты за общим процентом.

Дополнительные guardrails:

- Проверить, что `AGENTS.md` и `.codex/skills` актуальны.
- Добавить checklist для PR с рефакторингом:
  - no raw receipt/file/user data logging
  - tests updated
  - EN/RU/PL l10n updated when visible text changes
  - database migration considered
  - import pipeline behavior preserved

Риск:

- Если baseline уже красный, рефакторинг будет сложно отличить от старых проблем.

## Этап 1. Разделить provider composition

Цель: разгрузить `lib/app/providers.dart` и сделать ownership зависимостей очевидным.

Предлагаемые файлы:

- `lib/app/providers/repository_providers.dart`
- `lib/app/providers/service_providers.dart`
- `lib/app/providers/platform_providers.dart`
- `lib/app/providers/settings_providers.dart`
- `lib/app/providers/ui_state_providers.dart`
- `lib/app/providers.dart` как barrel/export или compatibility facade

Задачи:

- Перенести repository providers без изменения public names.
- Перенести platform providers (`pdfTextExtractorProvider`, `fileImportServiceProvider`).
- Перенести settings/logging providers.
- Перенести selected month/search/filter providers в UI state group.
- Сохранить импорт `package:receipts/app/providers.dart` рабочим для существующего кода.

Критерии готовности:

- Поведение приложения не меняется.
- Tests compile без массового изменения imports.
- Новые providers имеют понятное место.

Тесты:

- `flutter test`
- focused tests для import/settings при необходимости.

## Этап 2. Оформить database package

Цель: сделать SQLite слой более модульным и готовым к миграциям.

Предлагаемая структура:

```text
lib/data/database/
├── database_helper.dart
├── database_schema.dart
├── database_migrations.dart
├── seed_data.dart
└── aggregate_tables.dart
```

Задачи:

- Разделить текущий `lib/data/database.dart` на schema, migrations, seed/default data.
- Оставить compatibility export `lib/data/database.dart`, если это уменьшит churn.
- Вынести category/merchant seed data в отдельный модуль.
- Добавить явное описание db versions и migration history.
- Проверить, что test harness использует новый helper без изменения поведения.
- Сохранить поведение static singleton/configuration:
  - `DatabaseHelper.close`
  - `configureForTesting`
  - `databaseFactory`/FFI setup
  - `_databaseNameOverride`
  - legacy database name fallback from `biedronka_expenses.db`

Критерии готовности:

- Fresh database создаётся с той же схемой.
- Existing migrations продолжают работать.
- Repositories не знают деталей seed/migration.
- Test isolation не сломан: каждый test harness получает отдельную БД.
- Legacy database fallback всё ещё открывает старую БД, если новой ещё нет.

Тесты:

- Repository tests.
- Import pipeline tests.
- Новый migration smoke test: create old-ish schema or use existing version path, then open upgraded DB.
- Fresh schema equivalence smoke: таблицы/индексы/seed data соответствуют текущему поведению.

## Этап 3. Выделить application/use-case слой

Цель: убрать сценарную бизнес-логику из feature services и repositories.

Кандидаты:

- `application/import/import_receipts_use_case.dart`
- `application/import/import_receipt_result_mapper.dart`
- `application/analytics/rebuild_aggregates_use_case.dart`
- `application/receipts/delete_receipt_use_case.dart`
- `application/settings/update_sentry_setting_use_case.dart`

Задачи:

- Перенести orchestration из `ImportService` в use case.
- Оставить feature controller тонким: pick files -> call use case -> expose state.
- Уточнить границы:
  - parser только парсит
  - repositories только читают/пишут
  - use case решает порядок операций
- Сделать use cases тестируемыми через plain Dart/Riverpod container.

Критерии готовности:

- Import flow сохраняет behavior:
  - hash duplicate
  - PDF extraction
  - JSON fallback
  - heuristic duplicate
  - insert with items
  - aggregates update
  - safe error message
- Tests не требуют Flutter UI для проверки import orchestration.

Тесты:

- `flutter test test/import_pipeline_test.dart`
- parser tests
- добавить use-case specific tests, если текущих недостаточно.

## Этап 4. Укрепить privacy/logging framework

Цель: завершить формализацию privacy/logging framework после ранних guardrails из этапа 0.

Задачи:

- Добавить `core/privacy/sanitizer.dart`.
- Ввести типизированный `SafeLogEvent` или похожий contract.
- Обновить `ErrorLogService`:
  - не писать raw `safUri`, если это может раскрывать путь пользователя
  - не писать raw parser text/details
  - использовать allowlist полей
- Проверить все `developer.log`, Sentry breadcrumbs и local logs.
- Обновить `docs/privacy.md`, если фактическое поведение отличается.

Критерии готовности:

- Логировать можно только безопасные технические признаки.
- Import errors still debuggable without exposing receipt content.
- Privacy docs соответствуют коду.

Тесты:

- Unit tests для sanitizer.
- Import error logging test через fake filesystem/service, если вводится abstraction.

## Этап 5. Нормализовать domain value objects

Цель: уменьшить ошибки с money/date/category ids.

Кандидаты:

- `MoneyAmount` или минимальный helper для currency formatting/rounding.
- `ReceiptMonth` или расширение текущего `MonthDateRange`.
- `CategoryId` или строгий normalize layer.

Задачи:

- Не делать большой migration моделей сразу.
- Начать с helpers/value objects в местах с высокой ошибочностью:
  - parser amount parsing
  - duplicate amount tolerance
  - monthly filters
  - aggregate keys
- Постепенно заменить ad hoc `DateTime(year, month)` и raw amount comparison.

Критерии готовности:

- Меньше ручных month range calculations.
- Денежные проверки в тестах стандартизированы.
- Category normalization единообразна.

Тесты:

- Unit tests для value objects/helpers.
- Existing parser/import tests.

## Этап 6. Разделить крупные UI файлы

Цель: сделать feature UI легче поддерживать без изменения UX.

Приоритет:

1. `dashboard_view.dart`
2. `month_view.dart`
3. `receipts_view.dart`
4. `receipt_details_view.dart`
5. `settings_view.dart`

Подход:

- Выносить только повторяемые или крупные private widgets.
- Не менять visual design в том же PR, где делается structural split.
- Создавать feature-local subfolders:

```text
lib/features/dashboard/
├── dashboard_view.dart
├── widgets/
├── dashboard_controller.dart
└── dashboard_view_model.dart
```

Задачи:

- Вынести formatting в small helpers или view model.
- Вынести action handlers в controllers/use cases.
- Оставить widgets максимально dumb.
- Проверить responsive layout после каждого крупного split.

Критерии готовности:

- UI behavior unchanged.
- Файлы стали меньше и проще читать.
- Widget tests или integration tests продолжают проходить.

## Этап 7. View models для экранов аналитики

Цель: уменьшить количество вычислений и state mapping внутри виджетов.

Кандидаты:

- `DashboardViewModel`
- `MonthViewModel`
- `ReceiptsFilterState`
- `ReceiptDetailsViewModel`

Задачи:

- Маппить domain models в UI-ready данные вне build methods.
- Централизовать currency/date formatting decisions.
- Сохранить локализацию на UI boundary: view model может принимать locale/formatter, но не должен напрямую зависеть от BuildContext.

Критерии готовности:

- Build methods короче.
- Empty/error/loading states читаются явно.
- Tests могут проверять mapping без pumpWidget.

## Этап 8. Улучшить test framework

Цель: сделать тесты быстрыми, изолированными и удобными для будущих рефакторингов.

Задачи:

- Расширить `TestAppHarness`:
  - common repository/service overrides
  - fake settings repo
  - fake pdf extractor
  - optional seeded database helpers
- Добавить factories/builders для domain models.
- Ввести naming conventions для тестов:
  - parser tests
  - repository tests
  - use-case tests
  - widget tests
  - integration tests
- Добавить focused test commands в docs.

Критерии готовности:

- Новый use case можно протестировать без копирования boilerplate.
- Database tests не зависят от порядка запуска.
- Coverage gate остаётся применимым.

## Этап 9. L10n workflow hardening

Цель: снизить риск ручных конфликтов в generated localization files.

Задачи:

- Зафиксировать команду генерации localizations.
- Решить, являются ли `app_localizations*.dart` source-controlled generated files или build artifacts.
- Зафиксировать, что рабочие locales сейчас EN/RU/PL:
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_ru.arb`
  - `lib/l10n/app_pl.arb`
  - generated `app_localizations_en/ru/pl.dart`
- Если generated files остаются в git:
  - добавить правило: ARB -> generate -> commit all generated changes together
  - добавить тест/CI check на синхронность ARB и generated output
- Если generated files удаляются из git:
  - обновить `.gitignore`
  - проверить CI/build pipeline

Критерии готовности:

- Добавление строки в ARB имеет один понятный workflow.
- Конфликты generated l10n становятся редкими и предсказуемыми.

## Этап 10. CI и quality gates

Цель: сделать refactoring-safe pipeline.

Задачи:

- Сначала сделать inventory текущих workflows:
  - Android debug build/analyze/unit tests
  - Sonar coverage job
  - manual Android integration tests
- Проверить GitHub Actions:
  - analyze
  - unit tests
  - coverage gate
  - Android integration tests
  - Sonar scan, если используется
- Унифицировать Flutter SDK version между workflows, если нет причины держать разные версии.
- Решить, где реально живёт coverage gate:
  - `flutter test --coverage` только генерирует отчёт
  - `dart run tool/test_with_coverage.dart --min-coverage=...` проверяет минимум
- Разделить slow/fast jobs.
- Сохранить `workflow_dispatch` для дорогих integration suites, если они не должны блокировать каждый PR.
- Убедиться, что PR status ясно показывает failing layer.

Критерии готовности:

- Малые PR быстро получают feedback.
- Integration tests доступны, но не блокируют каждую локальную итерацию без необходимости.

## 8. Предлагаемый порядок PR

Рекомендуется делать маленькие PR, каждый с понятным behavioral surface.

1. Baseline + privacy/logging guardrails + минимальные P0 tests.
2. L10n workflow decision для EN/RU/PL, если ближайшие PR будут трогать UI text/generated localization files.
3. Provider split без изменения поведения.
4. Database package split с compatibility exports и migration/test-isolation smoke tests.
5. Use-case layer для import pipeline с заранее выбранной стратегией repository dependencies и aggregate ownership.
6. Privacy/logging framework completion, если на PR 1 были только минимальные guardrails.
7. Test harness helpers and factories.
8. Dashboard UI split.
9. Month/receipts UI split.
10. View models для analytics screens.
11. CI quality gate cleanup.

Feature work отдельно от refactor PR:

- clear all data
- delete receipt
- recategorization
- open PDF/source file
- bulk import UX changes

## 9. Definition of Done для каждого этапа

Каждый этап считается завершённым, если:

- Поведение пользователя не изменилось, кроме явно описанных изменений.
- `flutter analyze` проходит или известные warnings зафиксированы.
- Релевантные `flutter test ...` проходят.
- Нет новых privacy risks.
- Нет raw receipt/file/user data в developer logs, local logs, telemetry, Sentry payloads или test output.
- Документация обновлена, если изменился workflow.
- PR достаточно мал, чтобы его можно было ревьюить по смыслу.

## 10. Правило саб-планов и трекер мастер-плана

Мастер-план описывает направление эпика, но не должен быть единственным источником задач для конкретного PR. Перед началом каждой фазы или крупного раздела нужно создать или обновить отдельный саб-план в `docs/refactoring_subplans/`.

Саб-план обязателен для:

- каждой фазы из раздела 7;
- каждого PR из раздела 8, если PR не является чисто документационным;
- любого work package, который меняет import pipeline, database, providers, logging/privacy, l10n workflow, CI или test harness.

Минимальное содержание саб-плана:

- ссылка на фазу мастер-плана;
- статус;
- scope и non-goals;
- current state check по фактическому коду;
- implementation steps;
- affected files;
- risks and mitigations;
- tests/checks;
- phase-specific Definition of Done;
- completion notes и follow-ups.

После завершения саб-плана нужно:

- отметить его статус и completion notes;
- обновить этот мастер-план, если изменился порядок, scope, риски или DoD;
- обновить master tracker ниже;
- записать, какие проверки были запущены и какие follow-ups остались.

### Master Plan Tracker

| Phase / Work Package | Status | Sub-plan | Last Updated | Notes |
| --- | --- | --- | --- | --- |
| Phase 0: baseline + privacy/logging guardrails | complete | `docs/refactoring_subplans/phase_0_privacy_logging_guardrails.md` | 2026-06-02 | Guardrails implemented; analyze/tests passed; coverage baseline 35.35%. |
| Phase 0b: repository/aggregate/month helper P0 tests | complete | `docs/refactoring_subplans/phase_0b_repository_aggregate_tests.md` | 2026-06-02 | P0 data tests added; rebuildAll legacy category normalization fixed; coverage baseline 45.56%. |
| L10n workflow decision for EN/RU/PL | complete | `docs/refactoring_subplans/l10n_workflow_decision.md` | 2026-06-02 | Generated files stay source-controlled; workflow documented in `docs/l10n_workflow.md`. |
| Phase 1: provider split | complete | `docs/refactoring_subplans/phase_1_provider_split.md` | 2026-06-02 | `lib/app/providers.dart` is now a compatibility barrel; provider groups split mechanically. |
| Phase 2: database package split | complete | `docs/refactoring_subplans/phase_2_database_package_split.md` | 2026-06-02 | Database package split complete; schema/migration/legacy fallback smoke tests added; coverage baseline 47.78%. |
| Phase 3: import use-case layer | complete | `docs/refactoring_subplans/phase_3_import_use_case_layer.md` | 2026-06-02 | Import orchestration moved to `application/import`; `ImportService` remains a compatibility wrapper. |
| Phase 4: privacy/logging framework completion | complete | `docs/refactoring_subplans/phase_4_privacy_logging_completion.md` | 2026-06-02 | Audit complete; privacy docs updated; Android embedded payload dumping disabled. |
| Phase 8: test harness helpers and factories | complete | `docs/refactoring_subplans/phase_8_test_harness_helpers.md` | 2026-06-02 | Shared domain factories added; duplicated data-test builders removed. |
| Phase 6: Dashboard UI split | complete | `docs/refactoring_subplans/phase_6_dashboard_ui_split.md` | 2026-06-04 | Dashboard widget extraction complete; focused Dashboard test, analyzer, and full test suite passed. |
| Phase 6: Month UI split | complete | `docs/refactoring_subplans/phase_6_month_ui_split.md` | 2026-06-04 | Month widget extraction complete; focused Month test, analyzer, and full test suite passed. |
| Phase 6: Receipts UI split | complete | `docs/refactoring_subplans/phase_6_receipts_ui_split.md` | 2026-06-04 | Receipts smoke coverage and widget extraction complete; focused test, analyzer, and full test suite passed. |
| Phase 6: Receipt Details UI split | complete | `docs/refactoring_subplans/phase_6_receipt_details_ui_split.md` | 2026-06-04 | Receipt Details smoke coverage and widget extraction complete; focused test, analyzer, and full test suite passed. |
| Phase 6: Settings UI split | complete | `docs/refactoring_subplans/phase_6_settings_ui_split.md` | 2026-06-05 | Settings smoke coverage and section extraction complete; focused test, analyzer, and full test suite passed. |
| Phase 7: Dashboard view model | complete | `docs/refactoring_subplans/phase_7_dashboard_view_model.md` | 2026-06-05 | Dashboard month-selection mapping extracted and tested; focused tests, analyzer, and full test suite passed. |
| Phase 7: Month view model | complete | `docs/refactoring_subplans/phase_7_month_view_model.md` | 2026-06-05 | Month month-selection and overview metric mapping extracted and tested; focused tests, analyzer, and full test suite passed. |
| Phase 7: Receipts filter state | complete | `docs/refactoring_subplans/phase_7_receipts_filter_state.md` | 2026-06-05 | Receipts filtering and filter-month option mapping extracted and tested; focused tests, analyzer, and full test suite passed. |
| Phase 7: remaining analytics view models | not started | TBD | 2026-06-05 | Create separate sub-plans before Receipt Details or other view model extraction. |
| Phase 10: CI quality gates | not started | TBD | 2026-05-30 | Include Flutter version inventory and coverage gate decision. |

Tracker status values:

- `not started`
- `planned`
- `in progress`
- `blocked`
- `complete`
- `superseded`

## 11. Риски и mitigation

| Риск | Почему важно | Mitigation |
| --- | --- | --- |
| Большой рефакторинг ломает import pipeline | Импорт - главный пользовательский flow | Делать use-case migration отдельно и покрыть import tests |
| SQLite migration ломает существующие данные | Пользовательские чеки локальные и без backup | Fresh schema + migration tests + no destructive defaults |
| Generated l10n conflicts | Уже есть много generated files | Формализовать generation workflow |
| Privacy regression в logging | Чеки содержат чувствительные данные | Safe logging allowlist + sanitizer tests |
| UI split меняет UX случайно | Большие виджеты легко сломать | Один PR на экран, screenshots/manual smoke |
| Repositories становятся thin but fragmented | Слишком много абстракций | Выделять use cases только вокруг реальных сценариев |

## 12. Метрики успеха

После рефакторинга должно быть заметно:

- `lib/app/providers.dart` стал тонким composition/export файлом.
- Import orchestration тестируется без UI.
- Database schema/migrations читаются отдельно от seed data.
- UI файлы основных экранов уменьшены и разделены на виджеты/view models.
- Новые фичи добавляются по повторяемому шаблону.
- Privacy rules применяются не только в документах, но и в коде logging.
- Тестовый harness уменьшает boilerplate для новых тестов.

## 13. Открытые решения

Перед началом этапов нужно отдельно решить:

- Оставляем ли generated `app_localizations*.dart` в репозитории и как проверяем синхронность EN/RU/PL ARB с generated output.
- Вводим ли Riverpod code generation или остаёмся на ручных providers.
- Нужен ли формальный `application/` layer сразу или сначала достаточно `features/*/services`.
- Если вводим `application/`, зависит ли он временно от concrete repositories или сначала вводятся repository interfaces/ports.
- Кто владеет aggregate updates и `DatabaseUpdateBus` после use-case refactor: repositories или use cases.
- Храним ли local debug import logs вообще, какие поля допустимы, и нужен ли stack trace в локальном файле.
- Нужны ли golden tests для dashboard/month screens перед UI split.
- Считаем ли clear data/delete receipt/recategorization частью отдельной feature work, а не framework refactor.

## 14. Первые рекомендуемые действия

Минимальный стартовый набор:

1. Запустить baseline: `flutter analyze`, `flutter test`, `dart run tool/test_with_coverage.dart --min-coverage=0`.
2. Сделать PR 1: privacy/logging guardrails + минимальные P0 tests для import errors/logging.
3. Сделать PR 2: P0 tests для repositories/aggregates/month helpers, достаточные перед database/use-case переносами.
4. Зафиксировать l10n workflow для EN/RU/PL generated files, если ближайшие PR затрагивают UI text.
5. Сделать PR 3: split `lib/app/providers.dart` на provider groups с backward-compatible export.
6. Сделать PR 4: вынести `lib/data/database.dart` в `lib/data/database/` с compatibility export, legacy fallback и migration/test-isolation smoke tests.
7. Сделать PR 5: перенести import orchestration в `application/import`, заранее выбрав repository dependency и aggregate ownership strategy.

Эти шаги создадут основу для дальнейшего рефакторинга без изменения пользовательского поведения.
