# AmountRange Value Object

## Master Plan Link

- Master phase: follow-up from `docs/refactoring_subplans/phase_5_receipt_month_value_object.md` and `docs/refactoring_subplans/phase_7_receipts_filter_state.md`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-21

## Scope

- Add a pure Dart `AmountRange` value object for inclusive receipt amount filtering.
- Replace `RangeValues` provider state with `AmountRange`.
- Keep Flutter `RangeValues` only at the `RangeSlider` widget adapter boundary.
- Update `ReceiptsFilterState` to depend on `AmountRange` instead of primitive min/max values.
- Add focused tests for range behavior and update existing filter/widget tests.

## Non-goals

- Do not change the visible slider limits, divisions, labels, or filter behavior.
- Do not add currency semantics to amount ranges.
- Do not change receipt repository/database queries.
- Do not change localization text.

## Current State Check

- Files inspected:
  - `lib/application/receipts/receipts_filter_state.dart`
  - `lib/app/providers/ui_state_providers.dart`
  - `lib/features/receipts/receipts_view.dart`
  - `lib/features/receipts/widgets/search_and_filters.dart`
  - `test/application/receipts/receipts_filter_state_test.dart`
  - `test/features/receipts/receipts_view_test.dart`
- Existing behavior confirmed:
  - `receiptsAmountRangeProvider` currently stores Flutter `RangeValues(0, 1000)`.
  - `ReceiptsFilterState` receives primitive `minAmount` and `maxAmount`.
  - Amount filtering is inclusive: `total >= minAmount && total <= maxAmount`.
  - `SearchAndFilters` is the only widget that needs `RangeValues` for `RangeSlider`.

## Implementation Steps

1. Add `lib/domain/value_objects/amount_range.dart`.
2. Add focused tests for inclusive containment and equality.
3. Update `ReceiptsFilterState` to use `AmountRange`.
4. Update providers to store `AmountRange`.
5. Convert `AmountRange` to/from `RangeValues` at `SearchAndFilters`.
6. Run focused tests, analyzer, and full test suite.
7. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `lib/domain/value_objects/amount_range.dart`
- `lib/application/receipts/receipts_filter_state.dart`
- `lib/app/providers/ui_state_providers.dart`
- `lib/features/receipts/receipts_view.dart`
- `lib/features/receipts/widgets/search_and_filters.dart`
- `test/domain/value_objects/amount_range_test.dart`
- `test/application/receipts/receipts_filter_state_test.dart`
- `test/features/receipts/receipts_view_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/amount_range_value_object.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Widget adapter accidentally changes slider behavior. | Keep slider min/max/divisions and labels unchanged; only convert values. |
| Value object rejects existing valid ranges. | Use the same inclusive semantics and default `0..1000` range. |
| Application layer gains Flutter dependency. | Keep `RangeValues` imports only in UI/widget files. |

## Tests And Checks

- [x] `dart format <changed dart files>`
- [x] `flutter test test/domain/value_objects/amount_range_test.dart`
- [x] `flutter test test/application/receipts/receipts_filter_state_test.dart test/features/receipts/receipts_view_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] `AmountRange` exists as a pure Dart value object.
- [x] Receipts provider/filter state no longer store Flutter `RangeValues`.
- [x] `RangeValues` remains only at the `RangeSlider` adapter boundary.
- [x] Focused tests, analyzer, and full tests pass.
- [x] Master plan tracker updated.

## Completion Notes

- Completed on: 2026-06-21
- Tests run:
  - `dart format <changed dart files>`
  - `flutter test test/domain/value_objects/amount_range_test.dart`
  - `flutter test test/application/receipts/receipts_filter_state_test.dart test/features/receipts/receipts_view_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Keep `AmountRange` currency-agnostic and inclusive, matching the previous min/max filter semantics.
  - Store `AmountRange` in Riverpod state and convert to `RangeValues` only inside `SearchAndFilters`.
- Follow-ups:
  - None for this cleanup package.
