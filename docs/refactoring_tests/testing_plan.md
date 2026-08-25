# План тестирования проекта Receipts

## Статус

- Status: in progress
- Owner/agent: Codex
- Last updated: 2026-06-23
- Related docs:
  - `README.md`
  - `README_TESTING.md`
  - `docs/framework_refactoring_plan.md`
  - `docs/refactoring_subplans/phase_10_coverage_threshold.md`

## Scope

Этот документ фиксирует текущую тестовую стратегию Receipts и план ее усиления. Фокус: локальная обработка чеков, приватность, импорт PDF/JSON, SQLite-целостность, детерминированные деньги/даты, Riverpod state, локализация и Android integration flows.

План не заменяет маленькие execution sub-plans. Перед реализацией крупного блока из этого документа нужно создать отдельный файл в `docs/refactoring_tests/` или `docs/refactoring_subplans/`, если работа относится к master refactoring plan.

## Non-goals

- Не переписывать production code ради роста coverage.
- Не включать Android integration tests в обычный PR coverage gate.
- Не поднимать CI coverage threshold выше стабильного baseline без отдельного измерения.
- Не добавлять реальные чеки, NIP, file paths, URI, PDF payloads или персональные данные в fixtures.
- Не тестировать Android MethodChannel из unit/widget tests.

## Current State Check

Файлы и инфраструктура, на которых основан план:

- `test/helpers/test_environment.dart`
- `test/helpers/domain_factories.dart`
- `test/test_infra/fakes/fake_file_import_service.dart`
- `lib/di/test_overrides.dart`
- `tool/test_with_coverage.dart`
- `integration_test/app_flow_test.dart`
- `.github/workflows/android-debug.yml`
- `.github/workflows/sonar-scan.yml`
- `.github/workflows/integration_test.yml`
- `README.md`
- `README_TESTING.md`

Подтвержденное поведение:

- `flutter test` является быстрым unit/widget/repository gate.
- `tool/test_with_coverage.dart` запускает `flutter test --coverage --test-randomize-ordering-seed=random`.
- Coverage helper по умолчанию требует 70%, но CI Sonar workflow явно использует `--min-coverage=50`.
- Последний clean-plan baseline до начала Package 1: 51.05% line coverage, 1366/2676 lines.
- Current-workspace Package 1 baseline: 50.63% line coverage, 1496/2955 lines. См. `docs/refactoring_tests/baseline_low_coverage_map.md`.
- Coverage after Package 2 import/parser hardening: 51.54% line coverage, 1523/2955 lines. См. `docs/refactoring_tests/import_parser_hardening.md`.
- Coverage after Package 3 database repository hardening: 51.54% line coverage, 1523/2955 lines. См. `docs/refactoring_tests/database_repository_hardening.md`.
- Coverage after ImportView UI state coverage: 54.86% line coverage, 1621/2955 lines. См. `docs/refactoring_tests/ui_state_localization_coverage.md`.
- Android integration workflow manual-only и не блокирует каждый PR.

Known constraints:

- В рабочем дереве могут быть незавершенные изменения parser tests; baseline нужно перемерять только на согласованном состоянии ветки.
- Package 1 baseline 2026-06-23 измерен на dirty workspace с существующими изменениями в parser/instruction files; не считать его canonical clean-main baseline.
- Некоторые widget tests сейчас проверяют английский visible text напрямую. Для новых тестов предпочтительнее stable keys или локализованные строки.
- Integration suite сейчас покрывает один широкий flow. Это полезно для smoke, но плохо локализует причину падения.

## Testing Ownership

Fast PR gate:

- `flutter analyze`
- `flutter test`

Coverage and Sonar gate:

- `dart run tool/test_with_coverage.dart --min-coverage=50`
- Threshold 50% принадлежит CI и отражает текущий baseline. Не использовать helper без явного `--min-coverage`, пока baseline ниже default 70%.

Manual/device gate:

- `.\tool\it_android.ps1`
- `flutter test integration_test -d emulator-5554`

Focused local iteration:

```powershell
flutter test test/import_pipeline_test.dart
flutter test test/data/receipt_repository_test.dart
flutter test test/features/import/import_view_test.dart
flutter test --plain-name "duplicate"
```

## Test Data Rules

- Fixtures должны быть синтетическими или полностью обезличенными.
- Если fixture похож на реальный чек, заменить NIP, адреса, file names, URI и любые персональные значения.
- Failure messages не должны содержать raw payload. Тесты на ошибки обязаны проверять отсутствие sensitive substrings.
- Parser fixtures должны быть маленькими и purpose-built. Большие samples допустимы только когда структура документа важна для regression.
- Не хранить binary PDF fixtures без причины. Для parser regression предпочтительнее text/json samples; PDF нужен только для integration/platform-sensitive flows.

## Базовые правила написания тестов

- Использовать `bootstrapTestEnvironment`, `TestAppHarness` или `createTestContainer` для тестов с Riverpod/SQLite.
- Каждый тест с базой получает свежий temporary database path и закрывает `DatabaseHelper`.
- Платформенные сервисы подменять через providers или fakes.
- Для денег использовать `closeTo`.
- Для месяцев проверять half-open ranges `[monthStart, nextMonthStart)`.
- Для import failures/duplicates проверять и `status`, и `message`, если message является частью поведения.
- Для parser tests проверять дату, total, VAT, item count, representative items, merchant и categories.
- Для widget tests явно покрывать `AsyncValue` loading/error/data там, где screen зависит от async providers.

## Матрица покрытия

### Domain и value objects

Сейчас покрыто:

- `AmountRange`: inclusive boundaries, default receipt filter range, equality.
- `ReceiptMonth`: normalization, mapping from aggregate month, sorting, de-duplication.
- `ReceiptsFilterState`: merchant/date query, month filter, amount range, combined filters, month list construction.

Гепы:

- Нет отдельной таблицы boundary cases для денег: 0, max range, копейки, отрицательные значения как invalid input, если появится validation.
- Date boundary tests есть в data layer, но не всегда связаны с UI/view-model filters.

Усилить:

- Добавить boundary table tests для amount/date filters.
- При новых filters проверять отдельный predicate и combined predicate.
- Держать deterministic dates через explicit `DateTime`, не через `DateTime.now()`.

### Formatting и localization

Сейчас покрыто:

- `AppFormatters`: currency, receipt timestamp, receipt search date.
- `category_localizations_test`: каждая category имеет localized label.

Гепы:

- Недостаточно проверок locale-specific output для `en`, `pl`, `ru`.
- Widget tests местами завязаны на английский текст, что повышает стоимость l10n изменений.

Усилить:

- Добавить focused tests на currency/date formatting для всех поддержанных locale, когда формат виден пользователю.
- Для новых ARB placeholders проверять metadata и rendering во всех трех локалях.
- В widget tests для навигации и layout использовать `Key`, а не текст, если сам текст не является предметом проверки.

### Parser

Сейчас покрыто:

- Modern Biedronka layout.
- Jeronimo header, разбитый по строкам.
- E-receipt header.
- OCR text с ISO-like purchase date.
- JSON receipt export.
- Compact JPK fallback, когда legacy JSON sections неполные.

Гепы:

- Negative parser paths описаны неравномерно: пустой текст, поврежденный JSON, отсутствующие total/date, unsupported merchant.
- Мало regression fixtures для discounts, fractional quantity, decimal comma, VAT summary и mixed categories.
- Риски privacy regression в error reporting не отделены от parsing correctness.

Усилить:

- Перед изменением parser logic добавлять failing regression sample.
- Для каждого supported receipt format проверять merchant/date/total/VAT/items/categories.
- Для failure paths проверять безопасный тип ошибки или safe import message на уровне pipeline.
- Не расширять parser heuristics без теста на false positive, где неподдержанный текст не должен импортироваться.

### Import pipeline

Сейчас покрыто:

- Успешный импорт PDF text layer.
- Persist receipt and line items.
- Обновление monthly/category aggregates.
- Duplicate prevention по file hash.
- JSON fallback при PDF extraction failure.
- JSON payload, пришедший из PDF extraction.
- Generic safe message для unexpected import errors.

Гепы:

- Heuristic duplicate по merchant/date/total не покрыт отдельно от hash duplicate.
- Нет batch import сценария с partial success.
- Нет отдельной проверки empty picker result.
- Empty PDF pages и parser-controlled failures не разделены.
- Idempotency после ошибки не зафиксирована.

Усилить:

- Добавить tests: hash duplicate, heuristic duplicate, partial batch, empty picker, empty extraction pages, retry after failure.
- Для каждого error/duplicate result проверять user-safe `ImportResult.message`.
- Проверять, что aggregate tables не меняются после duplicate/error.
- Проверять update notifications только на successful writes.

### Database, repositories, aggregates

Сейчас покрыто:

- Fresh schema, indexes, seed data.
- Legacy database name fallback.
- Upgrade v1 legacy categories.
- Receipt insert/update/delete обновляют aggregates и update bus.
- `AggregatesUpdater.rebuildAll()` пересобирает totals и нормализует legacy category ids.
- `AnalyticsRepository`: month overview и last 12 months totals.
- Month date ranges.

Гепы:

- Migration tests покрывают не всю будущую chain strategy.
- Нет явного rollback test для multi-table write failure.
- Watch stream behavior покрыт точечно через update bus, но не как контракт для всех repository observers.
- SQL safety остается code review rule, не testable contract.

Усилить:

- Для каждой новой `dbVersion` добавлять legacy fixture или setup function с предыдущей schema.
- Добавить rollback test: ошибка при item insert не оставляет receipt без items.
- Добавить aggregate matrix: несколько чеков, разные месяцы, разные categories, delete last receipt in month.
- Для query-heavy методов проверять граничные месяцы через `[start, nextStart)`.
- SQL interpolation проверять review checklist и analyzer/lint rule, если появится подходящий lint.

### Feature view models

Сейчас покрыто:

- Dashboard month selection, empty totals, dropdown months.
- Month view model month selection, overview mapping, missing overview.
- Receipt details view model header, VAT summary, regular/fractional/discount rows.

Гепы:

- Error states для failed providers почти не описаны.
- Locale-sensitive display values проверяются ограниченно.
- View model tests не всегда фиксируют contracts для empty vs loading vs missing data.

Усилить:

- Для каждого view model добавить table tests: loading dependencies, empty data, populated data, error propagation/rendering contract.
- Для display strings использовать локализацию или formatter-level tests, не дублировать форматирование в view model tests.
- Проверять selected-month behavior при появлении новых данных после initial load.

### Widget tests

Сейчас покрыто:

- Dashboard empty state.
- Month empty state.
- Receipts empty state.
- ReceiptDetails happy path.
- ImportView loading state без empty state underneath.
- SettingsView main sections.

Гепы:

- Screen tests в основном smoke-level и не покрывают error/data matrices.
- ImportView не покрывает success/duplicate/partial failure rendering на widget level.
- Route-level shell/navigation покрыт в integration test, но не быстрым widget smoke.
- Language settings flow требует более явного coverage.

Усилить:

- Для каждого top-level screen иметь минимум loading/error/empty/data, если screen async.
- Использовать provider overrides для repository providers вместо реальной базы, когда проверяется rendering.
- Добавить route smoke test для `ShellRoute` tabs и details route.
- Для локализации проверять смену языка через settings provider/repository fake.

### Integration tests

Сейчас покрыто:

- Onboarding.
- Переходы по вкладкам.
- Import PDF через fake file import service.
- Receipt list и stats после импорта.
- Lifecycle pause/resume.
- Broken PDF extraction error.

Гепы:

- Один широкий flow может маскировать точную причину падения.
- Нет duplicate import, JSON import, receipt details navigation, persistence after restart.
- Manual-only workflow полезен, но regressions между ручными запусками возможны.

Усилить:

- Разбить suite на несколько focused `testWidgets`, если runtime останется приемлемым.
- Добавить duplicate import и JSON fallback flows.
- Добавить open receipt details after import.
- Добавить cold restart или rebuild app после import с проверкой SQLite persistence.
- Platform MethodChannel smoke держать отдельным manual-only test, если потребуется реальная Android PDF extraction проверка.

## Work Packages

### Package 1. Baseline and low-coverage map

Status: complete. Evidence: `docs/refactoring_tests/baseline_low_coverage_map.md`.

Scope:

- Перемерить coverage на чистом или согласованном состоянии ветки.
- Составить список low-coverage files/packages.

Steps:

1. Запустить `flutter analyze`.
2. Запустить `flutter test`.
3. Запустить `dart run tool/test_with_coverage.dart --min-coverage=0`.
4. Записать актуальный coverage и низкопокрытые области.
5. Решить, остается ли CI gate на 50%.

Risks:

| Risk | Mitigation |
| --- | --- |
| Baseline измерен поверх незавершенных parser changes. | Измерять только после явного решения по текущим dirty files. |
| Default helper threshold 70 случайно используется как gate. | Всегда указывать `--min-coverage` в CI и документации. |

Definition of Done:

- Coverage baseline обновлен.
- Low-coverage map зафиксирована.
- CI threshold не выше стабильного baseline.

### Package 2. Import and parser hardening

Status: complete. Evidence: `docs/refactoring_tests/import_parser_hardening.md`.

Scope:

- Закрыть самые рискованные gaps в parser/import.

Steps:

1. Добавить sanitized fixtures для empty text, malformed JSON, missing total/date, unsupported source.
2. Добавить import tests для heuristic duplicate, partial batch, empty picker, retry after failure.
3. Добавить privacy assertions на error messages.
4. Запустить focused parser/import tests и полный `flutter test`.

Risks:

| Risk | Mitigation |
| --- | --- |
| Fixtures случайно содержат реальные данные. | Использовать synthetic samples и review checklist на PII. |
| Parser начинает принимать неподдержанный мусор. | Добавить false-positive tests. |

Definition of Done:

- Success, fallback, duplicate, controlled failure и unexpected failure покрыты.
- Ошибки safe и не раскрывают payload.
- Aggregates не меняются после duplicate/error.

### Package 3. Database and migration hardening

Status: partially complete. Repository transaction and aggregate hardening complete in `docs/refactoring_tests/database_repository_hardening.md`; future migration-chain harness remains open for the next schema change.

Scope:

- Защитить schema, migration path, aggregates и transaction behavior.

Steps:

1. Добавить migration harness для previous-version setup.
2. Добавить rollback test для failed multi-table write.
3. Расширить aggregate matrix.
4. Проверить watch/update contracts.

Risks:

| Risk | Mitigation |
| --- | --- |
| Migration tests становятся хрупкими из-за точного SQL schema dump. | Проверять observable schema/behavior, не полный текст SQL. |
| Rollback test требует искусственной ошибки. | Использовать controlled invalid item/category или test-local fake boundary, не менять production code без нужды. |

Definition of Done:

- Fresh schema и migrated schema эквивалентны по behavior.
- Multi-table writes атомарны.
- Aggregates консистентны после insert/update/delete/rebuild.

### Package 4. UI state and localization coverage

Status: partially complete. ImportView state matrix complete in `docs/refactoring_tests/ui_state_localization_coverage.md`; Dashboard/Month/Receipts/ReceiptDetails/Settings state matrices remain open.

Scope:

- Расширить widget/view-model tests без Android emulator.

Steps:

1. Для screen-level widgets добавить loading/error/empty/data matrices.
2. Добавить ImportView rendering tests для success/duplicate/error/partial.
3. Добавить language/settings tests.
4. Добавить route smoke tests для shell tabs и receipt details.

Risks:

| Risk | Mitigation |
| --- | --- |
| Widget tests завязаны на brittle English text. | Использовать keys для навигации/layout и localized strings только когда проверяется текст. |
| Tests начинают использовать реальную базу там, где достаточно override. | Для rendering использовать provider overrides; database harness только для persistence behavior. |

Definition of Done:

- Top-level screens имеют явные state tests.
- Локализация проверена для новых visible strings.
- Tests остаются быстрыми и не требуют emulator.

### Package 5. Integration flow expansion

Scope:

- Расширить Android manual suite без превращения его в PR blocker.

Steps:

1. Добавить duplicate import flow.
2. Добавить JSON import flow.
3. Добавить receipt details navigation после import.
4. Добавить persistence after app rebuild/restart scenario.
5. Проверить runtime suite в CI/manual workflow.

Risks:

| Risk | Mitigation |
| --- | --- |
| Integration runtime становится слишком долгим. | Оставить workflow manual-only и разделить tests по focused flows. |
| Flakiness из-за ожиданий UI. | Использовать `pumpAndSettleSafe` и `waitForFinder`, не arbitrary delays. |

Definition of Done:

- Manual suite покрывает happy path, duplicate, fallback/error, details и persistence.
- Runtime остается в пределах workflow timeout.

### Package 6. Coverage gate raise

Scope:

- Поднять gate только после meaningful coverage growth.

Steps:

1. Измерить baseline после Packages 2-4.
2. Повторить coverage helper несколько раз с random ordering.
3. Поднять threshold небольшим шагом, максимум 5%.
4. Обновить Sonar workflow и docs.

Risks:

| Risk | Mitigation |
| --- | --- |
| Threshold blocks unrelated PR after small line-count change. | Держать запас ниже measured baseline. |
| Coverage растет за счет пустых tests. | Принимать только tests с behavioral assertions. |

Definition of Done:

- Новый gate стабильно проходит.
- Решение и baseline записаны.
- Integration tests не включены в coverage gate.

## Recommended Checklists

Parser/import changes:

- [ ] Sanitized fixture or inline sample added.
- [ ] Success and failure path covered.
- [ ] Duplicate/idempotency behavior covered when persistence changes.
- [ ] Error messages checked for sensitive data absence.
- [ ] `flutter test test/import_pipeline_test.dart`
- [ ] Parser-focused tests.

Database changes:

- [ ] `DatabaseHelper.dbVersion` updated when schema changes.
- [ ] Fresh schema updated.
- [ ] Migration path added.
- [ ] Migration-sensitive test added.
- [ ] Repository/aggregate focused tests run.

UI changes:

- [ ] ARB files updated for EN/RU/PL.
- [ ] Widget test added or updated.
- [ ] Loading/error/empty/data considered for async UI.
- [ ] No hardcoded new visible strings in widgets.

Platform changes:

- [ ] Interface remains behind provider.
- [ ] Fakes updated.
- [ ] Unit/widget tests do not call MethodChannel.
- [ ] Integration/manual test considered for real platform behavior.

PR checks:

- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] Focused tests for changed area
- [ ] `dart run tool/test_with_coverage.dart --min-coverage=50` when coverage or CI gate is affected
- [ ] Android integration workflow/manual local run when import shell, file picker, PDF extraction, lifecycle, or persistence is affected
- [ ] Privacy constraints checked for logs, telemetry, Sentry payloads, test output, and user-facing error messages
- [ ] Related refactoring sub-plan or test plan updated
