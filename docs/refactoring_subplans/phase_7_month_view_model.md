# Phase 7: Month View Model

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 7. View models для экранов аналитики`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-05

## Scope

- Introduce a small pure Dart `MonthViewModel` for Month screen mapping.
- Move dropdown-month derivation, selected-month fallback decision, and overview-derived metric values out of `MonthView`.
- Add focused unit tests for the extracted mapping behavior.
- Keep Month UI, providers, localized text, currency/date formatting, and widget structure unchanged.

## Non-goals

- Do not introduce app-wide presentation architecture.
- Do not move currency/date localization into the view model in this work package.
- Do not change Month providers or selected-month provider ownership.
- Do not alter category breakdown, receipt list, or navigation behavior.

## Current State Check

- Files inspected:
  - `lib/features/month/month_view.dart`
  - `test/features/month/month_view_test.dart`
  - `docs/refactoring_subplans/phase_7_dashboard_view_model.md`
- Existing behavior confirmed:
  - Month already has widget smoke coverage.
  - `MonthView` still owns `_ensureSelectedMonthIsAvailable`, `_buildDropdownMonths`, and `_isSameMonth`.
  - Month fallback behavior prefers the last month with positive total if the current selected month has no data.
  - Dropdown options include positive-total months, or all returned months if no month has positive total, plus the selected month.
  - Overview data is mapped to total amount and receipt count inside the widget.
- Known gaps:
  - Currency/date formatting still lives in widgets and remains out of this package.

## Implementation Steps

1. Add `lib/features/month/month_view_model.dart`.
2. Move Month month list and fallback selection rules into the view model.
3. Move overview-derived total amount and receipt count into the view model.
4. Update `month_view.dart` to consume the view model while preserving UI behavior.
5. Add `test/features/month/month_view_model_test.dart`.
6. Run formatter, focused Month tests, analyzer, and full test suite.
7. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `lib/features/month/month_view.dart`
- `lib/features/month/month_view_model.dart`
- `test/features/month/month_view_model_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_7_month_view_model.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Selected-month fallback changes and Month opens on a different month. | Mirror Dashboard view model tests for positive-total, zero-total, and missing-selected-month cases. |
| Overview-derived values drift from UI behavior. | Add tests for null and populated overview data. |
| View model starts depending on Flutter/l10n too early. | Keep it pure Dart and only use domain models. |

## Tests And Checks

- [x] `dart format lib/features/month/month_view.dart lib/features/month/month_view_model.dart test/features/month/month_view_model_test.dart`
- [x] `flutter test test/features/month/month_view_model_test.dart test/features/month/month_view_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Month month-selection and overview metric mapping lives in `MonthViewModel`.
- [x] Month UI behavior is unchanged.
- [x] Focused view model tests pass.
- [x] Existing Month widget smoke test passes.
- [x] Analyzer and full tests pass or any existing unrelated failures are documented.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-05
- Tests run:
  - `dart format lib/features/month/month_view.dart lib/features/month/month_view_model.dart test/features/month/month_view_model_test.dart`
  - `flutter test test/features/month/month_view_model_test.dart test/features/month/month_view_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Extract only pure month-selection and overview-derived metrics in this package.
  - Keep currency/date localization in widgets for now because changing formatter ownership would broaden the package.
  - Keep selected-month provider ownership unchanged.
- Follow-ups:
  - Create a separate sub-plan before moving receipts filter state or presentation mapping.
  - Consider consolidating duplicate month-selection logic between Dashboard and Month only if a future package needs it.
