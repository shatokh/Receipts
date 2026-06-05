# Phase 8: Test Harness Helpers

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 8. Улучшить test framework`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-02

## Scope

- Add small domain model factories for tests.
- Reduce duplicate receipt/line item builders introduced by Phase 0b data tests.
- Keep existing `TestAppHarness` behavior unchanged.

## Non-goals

- Do not redesign the whole test harness.
- Do not add broad fake repository layers.
- Do not change production code.
- Do not move all tests to factories if it creates churn.

## Current State Check

- Files inspected:
  - `test/helpers/test_environment.dart`
  - `test/data/receipt_repository_test.dart`
  - `test/data/analytics_repository_test.dart`
- Existing behavior confirmed:
  - `TestAppHarness` provides isolated sqflite/Riverpod state.
  - Data tests have duplicate local `_receipt` and `_item` builders.
- Known gaps:
  - No shared domain factories exist yet.

## Implementation Steps

1. Add `test/helpers/domain_factories.dart`.
2. Refactor duplicated data test builders to shared factories.
3. Run affected data tests and full suite if needed.
4. Update completion notes and master plan tracker.

## Affected Files

- `test/helpers/domain_factories.dart`
- `test/data/receipt_repository_test.dart`
- `test/data/analytics_repository_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_8_test_harness_helpers.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Shared factories hide important test-specific data. | Keep factory arguments explicit for id, date, total, receiptId, and categoryId. |
| Refactor creates noisy test churn. | Only update tests with duplicated builders. |

## Tests And Checks

- [x] `flutter test test/data/receipt_repository_test.dart test/data/analytics_repository_test.dart`
- [x] `flutter test`

## Definition Of Done

- [x] Shared domain factories exist.
- [x] Duplicated local builders in affected tests are removed.
- [x] Affected tests pass.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-02
- Tests run:
  - `flutter test test/data/receipt_repository_test.dart test/data/analytics_repository_test.dart`
  - `flutter test test/data/receipt_repository_test.dart`
  - `flutter test`
- Decisions made:
  - Add `test/helpers/domain_factories.dart` with explicit `buildReceipt` and `buildLineItem` builders.
  - Keep `TestAppHarness` unchanged in this work package.
  - Refactor only tests with obvious duplicate local builders.
- Follow-ups:
  - Add settings/file/PDF fakes or seeded database helpers only when the next tests need them.
