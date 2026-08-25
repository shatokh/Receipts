# Database Repository Hardening

## Status

- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-23
- Parent plan: `docs/refactoring_tests/testing_plan.md`, Package 3

## Scope

- Add focused repository tests for transaction rollback and aggregate isolation.
- Preserve production database schema and repository code.
- Keep tests on `sqflite_common_ffi` through the existing `TestAppHarness`.

## Non-goals

- Do not change `DatabaseHelper.dbVersion`.
- Do not add migrations.
- Do not change SQL queries or aggregate implementation.
- Do not introduce emulator/integration coverage.

## Current State Check

Files inspected:

- `lib/data/repositories/receipt_repository.dart`
- `test/data/receipt_repository_test.dart`
- `test/helpers/test_environment.dart`
- `test/helpers/domain_factories.dart`

Existing behavior confirmed:

- `insertReceiptWithItems` writes receipt and line items inside one SQLite transaction.
- Aggregate updates happen after the transaction succeeds.
- Existing tests covered insert/update/delete aggregate behavior, but not rollback on failed item insert.

## Changes

Repository tests added:

- `insertReceiptWithItems rolls back receipt when item insert fails`
  - Uses duplicate line item ids to force a batch insert failure.
  - Verifies no receipt, line items, monthly totals, or category totals remain.
- `insertReceiptWithItems keeps aggregates isolated by month and category`
  - Inserts multiple receipts across August and September.
  - Verifies monthly totals and category totals do not bleed between months/categories.

## Affected Files

- `test/data/receipt_repository_test.dart`
- `docs/refactoring_tests/database_repository_hardening.md`
- `docs/refactoring_tests/testing_plan.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Rollback test depends on SQLite primary-key behavior. | Duplicate line item id uses an existing schema invariant and does not require production hooks. |
| Aggregate isolation test duplicates existing coverage too closely. | It adds multi-receipt, multi-month, multi-category assertions missing from prior single-receipt tests. |
| New tests make suite slower. | Tests reuse the existing FFI harness and add only two repository cases. |

## Tests And Checks

- [x] `dart format test/data/receipt_repository_test.dart`
  - File was already formatted.
  - Dart returned a telemetry access error for `%APPDATA%`, unrelated to file formatting.
- [x] `flutter test test/data/receipt_repository_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`
- [x] `dart run tool/test_with_coverage.dart --min-coverage=50`

## Coverage Evidence

- Coverage after Package 3: 51.54% line coverage, 1523/2955 lines.
- Coverage run seed: `2286671132`.
- Package 3 did not materially change line coverage because it strengthens already-covered repository paths.

## Definition Of Done

- [x] Transaction rollback behavior is covered.
- [x] Aggregate isolation across months and categories is covered.
- [x] Existing repository insert/update/delete tests still pass.
- [x] Analyzer and full fast test suite pass.
- [x] Coverage gate at `--min-coverage=50` passes.

## Completion Notes

- Completed on: 2026-06-23
- Decisions made:
  - No schema or migration changes were needed for this package.
  - Keep broader migration-chain harness work as future database hardening, not part of this narrow package.
- Follow-ups:
  - Add explicit migration-chain tests when `dbVersion` changes.
  - Package 4: UI state and localization coverage.
