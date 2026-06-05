# Phase 7: Receipts Filter State

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 7. View models для экранов аналитики`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-05

## Scope

- Introduce a pure Dart `ReceiptsFilterState` in `application/receipts`.
- Move receipt filtering and filter-month option derivation out of `app/providers` and `ReceiptsView`.
- Keep existing Riverpod provider names, filter UI, route behavior, localized text, and amount slider behavior unchanged.
- Add focused unit tests for receipt filtering and month-option mapping.

## Non-goals

- Do not move receipts filter providers out of `app/providers` in this package.
- Do not replace Flutter `RangeValues` provider state yet.
- Do not redesign Receipts UI or filtering controls.
- Do not add or change user-facing localization strings.

## Current State Check

- Files inspected:
  - `lib/app/providers/ui_state_providers.dart`
  - `lib/features/receipts/receipts_view.dart`
  - `lib/features/receipts/widgets/search_and_filters.dart`
  - `lib/domain/models/receipt_row.dart`
- Existing behavior confirmed:
  - `filteredReceiptsProvider` currently normalizes query and filters by merchant/date/month/amount.
  - `ReceiptsView` currently derives month filter options from `monthlyTotalsProvider`.
  - `receiptsAmountRangeProvider` still exposes Flutter `RangeValues`.
- Known gaps:
  - Receipts filter state still lives in app providers after this package; moving provider ownership closer to the feature should be separate.

## Implementation Steps

1. Add `lib/application/receipts/receipts_filter_state.dart`.
2. Move query/month/amount receipt filtering into `ReceiptsFilterState`.
3. Move filter-month option derivation into `ReceiptsFilterState`.
4. Update `ui_state_providers.dart` and `receipts_view.dart` to use the new state/helper without changing provider names.
5. Add `test/application/receipts/receipts_filter_state_test.dart`.
6. Run formatter, focused tests, analyzer, and full test suite.
7. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `lib/application/receipts/receipts_filter_state.dart`
- `lib/app/providers/ui_state_providers.dart`
- `lib/features/receipts/receipts_view.dart`
- `test/application/receipts/receipts_filter_state_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_7_receipts_filter_state.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Filtering behavior changes subtly. | Add focused tests for query, date query, month, amount range, and combined filters. |
| App providers depend on feature code. | Put the filter state in `application/receipts`, not `features/receipts`. |
| Flutter `RangeValues` leaks deeper into application. | Convert `RangeValues` to primitive min/max values at the provider boundary. |

## Tests And Checks

- [x] `dart format lib/application/receipts/receipts_filter_state.dart lib/app/providers/ui_state_providers.dart lib/features/receipts/receipts_view.dart test/application/receipts/receipts_filter_state_test.dart`
- [x] `flutter test test/application/receipts/receipts_filter_state_test.dart test/features/receipts/receipts_view_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Receipt filtering logic lives in `ReceiptsFilterState`.
- [x] Filter month option mapping lives in `ReceiptsFilterState`.
- [x] Public provider names and UI behavior are unchanged.
- [x] Focused filter tests pass.
- [x] Existing Receipts widget smoke test passes.
- [x] Analyzer and full tests pass or any existing unrelated failures are documented.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-05
- Tests run:
  - `dart format lib/application/receipts/receipts_filter_state.dart lib/app/providers/ui_state_providers.dart lib/features/receipts/receipts_view.dart test/application/receipts/receipts_filter_state_test.dart`
  - `flutter test test/application/receipts/receipts_filter_state_test.dart test/features/receipts/receipts_view_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Put `ReceiptsFilterState` in `application/receipts` so `app/providers` does not depend on `features`.
  - Keep existing public provider names and keep `RangeValues` at the app-provider/UI boundary.
  - Move filter-month option mapping out of `ReceiptsView` together with receipt filtering.
- Follow-ups:
  - Create a separate sub-plan before moving receipts filter providers closer to the feature.
  - Consider replacing `RangeValues` provider state with a pure amount-range value object in a future cleanup package.
