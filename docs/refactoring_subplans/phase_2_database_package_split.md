# Phase 2: Database Package Split

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 2. Оформить database package`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-02

## Scope

- Split `lib/data/database.dart` into focused files under `lib/data/database/`.
- Keep `lib/data/database.dart` as a backward-compatible export.
- Preserve fresh schema, v1 -> v2 migration, default seed data, legacy database fallback, and test database isolation behavior.
- Add smoke tests for fresh schema/seed, legacy fallback, and migration-sensitive behavior.

## Non-goals

- Do not increment `DatabaseHelper.dbVersion`.
- Do not add new tables, columns, indexes, or schema behavior.
- Do not move repositories or introduce repository interfaces.
- Do not change application/use-case orchestration.

## Current State Check

- Files inspected:
  - `lib/data/database.dart`
  - `lib/data/repositories/receipt_repository.dart`
  - `lib/data/repositories/analytics_repository.dart`
  - `test/helpers/test_environment.dart`
- Existing behavior confirmed:
  - `DatabaseHelper.dbVersion` is `2`.
  - Fresh schema creation creates merchants, categories, receipts, line_items, monthly_totals, and category_month_totals.
  - Fresh schema creates indexes for receipt timestamp, receipt total, and line item receipt id.
  - Fresh schema seeds canonical categories and default merchants.
  - Upgrade path from version 1 to 2 migrates legacy category ids to current category definitions.
  - Runtime database can fall back to `biedronka_expenses.db` when `receipts.db` does not exist.
  - Test harness relies on `DatabaseHelper.close` and sqflite FFI database path isolation.

## Implementation Steps

1. Create `lib/data/database/` package files:
   - `database_helper.dart`
   - `database_schema.dart`
   - `database_migrations.dart`
   - `seed_data.dart`
2. Move code mechanically without changing public `DatabaseHelper` API.
3. Replace `lib/data/database.dart` with compatibility export.
4. Add database smoke tests for fresh schema/seed/indexes.
5. Add migration smoke test for v1 legacy category normalization.
6. Add legacy fallback smoke test for `biedronka_expenses.db`.
7. Run formatter, analyze, focused tests, and full tests.
8. Update completion notes and master plan tracker.

## Affected Files

- `lib/data/database.dart`
- `lib/data/database/database_helper.dart`
- `lib/data/database/database_schema.dart`
- `lib/data/database/database_migrations.dart`
- `lib/data/database/seed_data.dart`
- `test/data/database_helper_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_2_database_package_split.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Static database singleton/test setup breaks. | Preserve `DatabaseHelper.close`, `configureForTesting`, `_databaseNameOverride`, and FFI setup behavior. |
| Fresh schema drifts during split. | Add smoke tests for tables, indexes, and seed data. |
| v1 -> v2 migration path regresses. | Add migration smoke test using an old schema fixture in a temp database. |
| Legacy database fallback regresses. | Add smoke test using `biedronka_expenses.db` without `receipts.db`. |

## Tests And Checks

- [x] `flutter test test/data/database_helper_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] `lib/data/database.dart` remains a compatibility export.
- [x] Fresh schema behavior is preserved.
- [x] v1 -> v2 migration behavior is preserved.
- [x] Legacy DB fallback behavior is preserved.
- [x] Test database isolation behavior is preserved.
- [x] Relevant tests/checks pass or known failures are documented.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-02
- Tests run:
  - `flutter test test/data/database_helper_test.dart`
  - `flutter analyze`
  - `flutter test`
  - `dart run tool/test_with_coverage.dart --min-coverage=0`
- Coverage baseline after Phase 2: 47.78% line coverage (688/1440 lines).
- Decisions made:
  - Keep `lib/data/database.dart` as a compatibility export.
  - Move schema creation, migrations, seed data, and helper singleton into separate files under `lib/data/database/`.
  - Preserve `DatabaseHelper.dbVersion = 2`; no schema version increment because this phase is a structural split only.
  - Add focused smoke tests for fresh schema/seed/indexes, legacy database fallback, and v1 -> v2 legacy category migration.
- Follow-ups:
  - Sqflite prints expected factory-change warnings in database helper tests because tests call `configureForTesting`; no behavior failure.
  - Future schema changes should add migration tests near `test/data/database_helper_test.dart`.
