# ReceiptMonth Data Range Cleanup

## Master Plan Link

- Master phase: follow-up from `docs/refactoring_subplans/phase_5_receipt_month_value_object.md`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-08

## Scope

- Reuse `ReceiptMonth` in data-layer month range normalization where it directly replaces duplicated `DateTime(year, month)` logic.
- Preserve existing SQL behavior and half-open month filters: `purchase_ts >= monthStart` and `purchase_ts < nextMonthStart`.
- Keep `MonthDateRange` as the data-layer range adapter because repositories already use its millisecond accessors.
- Run focused data tests plus analyzer/full suite.

## Non-goals

- Do not change SQLite schema, migrations, indexes, or `DatabaseHelper.dbVersion`.
- Do not change aggregate formulas, repository query semantics, or timestamp storage.
- Do not introduce repository ports/interfaces.
- Do not replace all `DateTime(year, month)` calls in UI widgets.

## Current State Check

- Files inspected:
  - `lib/domain/value_objects/receipt_month.dart`
  - `lib/data/month_date_range.dart`
  - `lib/data/aggregates_updater.dart`
  - `lib/data/repositories/receipt_repository.dart`
  - `lib/data/repositories/analytics_repository.dart`
  - `lib/data/repositories/category_repository.dart`
  - `test/data/month_date_range_test.dart`
- Existing behavior confirmed:
  - `ReceiptMonth` exposes `start` and `nextStart`.
  - `MonthDateRange` duplicates that construction internally.
  - Receipt repository and aggregate normalization still manually rebuild month starts in a few places.

## Implementation Steps

1. Update `MonthDateRange` to construct ranges from `ReceiptMonth`.
2. Replace repository/aggregate manual month normalization where this is a direct substitution.
3. Keep SQL query arguments and range boundaries unchanged.
4. Run focused data tests, analyzer, and full test suite.
5. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `lib/data/month_date_range.dart`
- `lib/data/aggregates_updater.dart`
- `lib/data/repositories/receipt_repository.dart`
- `lib/data/repositories/analytics_repository.dart`
- `test/data/month_date_range_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/receipt_month_data_range_cleanup.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Month boundary regression changes repository results. | Keep `MonthDateRange` tests and run repository/analytics tests. |
| Cleanup accidentally changes SQL filtering. | Preserve `>= start` and `< end` query predicates and parameter binding. |
| Scope expands into schema or aggregate behavior. | Do not edit schema/migrations; only replace month normalization plumbing. |

## Tests And Checks

- [x] `dart format <changed dart files>`
- [x] `flutter test test/data/month_date_range_test.dart`
- [x] `flutter test test/data/receipt_repository_test.dart test/data/analytics_repository_test.dart test/data/aggregates_updater_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Data-layer month range construction reuses `ReceiptMonth`.
- [x] Existing half-open month SQL filtering is preserved.
- [x] Focused data tests pass.
- [x] Analyzer and full tests pass.
- [x] Master plan tracker updated.

## Completion Notes

- Completed on: 2026-06-08
- Tests run:
  - `dart format <changed dart files>`
  - `flutter test test/data/month_date_range_test.dart`
  - `flutter test test/data/receipt_repository_test.dart test/data/analytics_repository_test.dart test/data/aggregates_updater_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Keep `MonthDateRange` as the data adapter and have it derive boundaries from `ReceiptMonth`.
  - Preserve all repository SQL predicates and timestamp storage behavior.
- Follow-ups:
  - None for this cleanup package.
