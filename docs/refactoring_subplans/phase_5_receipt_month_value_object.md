# Phase 5: Receipt Month Value Object

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 5. Нормализовать domain value objects`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-08

## Scope

- Introduce a small pure Dart `ReceiptMonth` value object in `domain/value_objects`.
- Centralize month normalization, sorting, equality, and conversion to `DateTime` month starts.
- Apply it to recent month-mapping hot spots in Dashboard, Month, and Receipts filter presentation logic.
- Keep public UI widget APIs using `DateTime` for now to avoid broad UI churn.

## Non-goals

- Do not migrate database schema or stored month columns.
- Do not replace `MonthDateRange` everywhere in data repositories in this package.
- Do not introduce money or category value objects in the same package.
- Do not change visible date/month formatting or selected-month provider ownership.

## Current State Check

- Files inspected:
  - `lib/data/month_date_range.dart`
  - `lib/features/dashboard/dashboard_view_model.dart`
  - `lib/features/month/month_view_model.dart`
  - `lib/application/receipts/receipts_filter_state.dart`
  - `lib/data/repositories/receipt_repository.dart`
  - `lib/data/repositories/analytics_repository.dart`
- Existing behavior confirmed:
  - Dashboard and Month view models normalize months with repeated `DateTime(year, month)` logic.
  - Receipts filter month options also repeat `DateTime(year, month)` mapping and descending sort.
  - `MonthDateRange` already preserves half-open `[monthStart, nextMonthStart)` behavior in data code.
- Known gaps:
  - Repositories still contain several month calculations; migrating them should be a separate package after this value object is proven.

## Implementation Steps

1. Add `lib/domain/value_objects/receipt_month.dart`.
2. Add `test/domain/value_objects/receipt_month_test.dart`.
3. Update `DashboardViewModel` month mapping to use `ReceiptMonth`.
4. Update `MonthViewModel` month mapping to use `ReceiptMonth`.
5. Update `ReceiptsFilterState.buildFilterMonths` to use `ReceiptMonth`.
6. Run formatter, focused tests, analyzer, and full test suite.
7. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `lib/domain/value_objects/receipt_month.dart`
- `lib/features/dashboard/dashboard_view_model.dart`
- `lib/features/month/month_view_model.dart`
- `lib/application/receipts/receipts_filter_state.dart`
- `test/domain/value_objects/receipt_month_test.dart`
- existing focused tests for Dashboard, Month, and Receipts filter mapping
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_5_receipt_month_value_object.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Month sorting or equality changes subtly. | Add direct value object tests and rerun existing focused mapping tests. |
| Value object leaks into UI APIs too early. | Keep widgets and providers accepting `DateTime`; convert at mapping boundaries. |
| Repository date range behavior changes. | Do not modify repository month range logic in this package. |

## Tests And Checks

- [x] `dart format lib/domain/value_objects/receipt_month.dart lib/features/dashboard/dashboard_view_model.dart lib/features/month/month_view_model.dart lib/application/receipts/receipts_filter_state.dart test/domain/value_objects/receipt_month_test.dart`
- [x] `flutter test test/domain/value_objects/receipt_month_test.dart test/features/dashboard/dashboard_view_model_test.dart test/features/month/month_view_model_test.dart test/application/receipts/receipts_filter_state_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] `ReceiptMonth` covers normalization, comparison, equality, and `DateTime` conversion.
- [x] Recent Dashboard/Month/Receipts month mapping uses `ReceiptMonth`.
- [x] UI behavior and selected-month values are unchanged.
- [x] Focused value object and mapping tests pass.
- [x] Analyzer and full tests pass or any existing unrelated failures are documented.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-08
- Tests run:
  - `dart format lib/domain/value_objects/receipt_month.dart lib/features/dashboard/dashboard_view_model.dart lib/features/month/month_view_model.dart lib/application/receipts/receipts_filter_state.dart test/domain/value_objects/receipt_month_test.dart`
  - `flutter test test/domain/value_objects/receipt_month_test.dart test/features/dashboard/dashboard_view_model_test.dart test/features/month/month_view_model_test.dart test/application/receipts/receipts_filter_state_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Start Phase 5 with a narrow date/month value object instead of money/category changes.
  - Keep UI and provider APIs on `DateTime` for now; convert at mapping boundaries.
  - Leave repository month range migration for a separate package.
- Follow-ups:
  - Consider using `ReceiptMonth` in repository/data month calculations in a separate package.
  - Consider a pure amount-range value object before changing `RangeValues` provider state.
  - Consider money formatting/value-object cleanup only after deciding formatter ownership.
