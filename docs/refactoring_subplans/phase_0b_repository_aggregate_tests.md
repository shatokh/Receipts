# Phase 0b: Repository Aggregate Tests

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, P0 repository/aggregate/month helper tests
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-02

## Scope

- Add focused P0 tests for repository writes, aggregate table consistency, update bus notifications, and month date boundaries.
- Cover the behavior needed before database package split and import use-case refactor.
- Use the existing `TestAppHarness` and isolated sqflite FFI databases.
- Keep production database/repository behavior unchanged unless a test exposes a real defect.

## Non-goals

- Do not split `lib/data/database.dart` in this phase.
- Do not introduce repository interfaces or application/use-case layer.
- Do not change SQLite schema, migrations, or dbVersion.
- Do not target the long-term coverage gate yet.

## Current State Check

- Files inspected:
  - `lib/data/repositories/receipt_repository.dart`
  - `lib/data/repositories/analytics_repository.dart`
  - `lib/data/aggregates_updater.dart`
  - `lib/data/month_date_range.dart`
  - `test/helpers/test_environment.dart`
- Existing behavior confirmed:
  - `ReceiptRepository.insertReceiptWithItems` writes receipt/items in a transaction and updates aggregates afterward.
  - `ReceiptRepository.updateReceipt` recalculates both current and previous months when purchase month changes.
  - `ReceiptRepository.deleteReceipt` deletes line items and receipt in one transaction, then updates aggregates.
  - `AggregatesUpdater` normalizes legacy category ids.
  - `MonthDateRange` uses `[monthStart, nextMonthStart)` boundaries.
- Known gaps:
  - No direct repository tests exist yet.
  - No direct month helper tests exist yet.
  - Database watcher/update bus behavior is not directly covered.

## Implementation Steps

1. Add month range unit tests for normal month, December rollover, leap-year February, and `forYearMonth`.
2. Add receipt repository tests for insert/update/delete aggregate behavior and update bus emission.
3. Add aggregate updater tests for `rebuildAll` and legacy category id normalization.
4. Add analytics repository smoke tests for month overview and last-12-month totals if scope remains small.
5. Run focused tests and full suite.
6. Update completion notes and master plan tracker.

## Affected Files

- `test/data/month_date_range_test.dart`
- `test/data/receipt_repository_test.dart`
- `test/data/aggregates_updater_test.dart`
- `test/data/analytics_repository_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_0b_repository_aggregate_tests.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Tests duplicate too much fixture setup. | Use small helper builders in test files first; extract shared factories later in Phase 8. |
| Repository tests become brittle around update bus timing. | Assert one emitted event with timeout instead of exact stream internals. |
| Scope grows into database refactor. | Keep this phase test-only unless a real bug is exposed. |

## Tests And Checks

- [x] `flutter test test/data/month_date_range_test.dart`
- [x] `flutter test test/data/receipt_repository_test.dart`
- [x] `flutter test test/data/aggregates_updater_test.dart`
- [x] `flutter test test/data/analytics_repository_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Month helper behavior is covered for important boundaries.
- [x] Receipt write/update/delete aggregate behavior is covered.
- [x] Update bus emission after repository writes is covered.
- [x] Aggregate rebuild and legacy category normalization are covered.
- [x] Analytics repository smoke behavior is covered or explicitly deferred.
- [x] Relevant tests/checks pass or known failures are documented.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-02
- Tests run:
  - `flutter test test/data/month_date_range_test.dart test/data/receipt_repository_test.dart test/data/aggregates_updater_test.dart test/data/analytics_repository_test.dart`
  - `flutter test test/data/receipt_repository_test.dart`
  - `flutter analyze`
  - `flutter test`
  - `dart run tool/test_with_coverage.dart --min-coverage=0`
- Coverage baseline after Phase 0b: 45.56% line coverage (656/1440 lines).
- Decisions made:
  - Keep P0 tests local to `test/data/` for now; shared builders/factories can wait until Phase 8.
  - Fix `AggregatesUpdater.rebuildAll` so full rebuild normalizes legacy category ids the same way incremental `updateForMonths` already does.
  - Cover analytics repository through repository writes rather than raw SQL fixtures, except where direct legacy fixture setup is required.
- Follow-ups:
  - Database watch stream tests can be expanded during provider/database split if more watch behavior changes.
  - Migration smoke tests remain for Phase 2 database package split.
