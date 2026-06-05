# Phase 7: Dashboard View Model

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 7. View models для экранов аналитики`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-05

## Scope

- Introduce a small pure Dart `DashboardViewModel` for Dashboard month-selection mapping.
- Move dropdown-month derivation and selected-month fallback decision out of `DashboardView`.
- Add focused unit tests for the extracted mapping behavior.
- Keep Dashboard UI, providers, localized text, currency/date formatting, and widget structure unchanged.

## Non-goals

- Do not introduce app-wide presentation architecture.
- Do not move currency/date localization into the view model in this work package.
- Do not change Dashboard providers or selected-month provider ownership.
- Do not alter chart, KPI, category, or quick insight rendering.

## Current State Check

- Files inspected:
  - `lib/features/dashboard/dashboard_view.dart`
  - `lib/features/dashboard/widgets/kpi_cards.dart`
  - `lib/features/dashboard/widgets/monthly_chart.dart`
  - `test/features/dashboard/dashboard_view_test.dart`
- Existing behavior confirmed:
  - Dashboard already has widget smoke coverage.
  - `DashboardView` still owns `_ensureSelectedMonthIsAvailable`, `_buildDropdownMonths`, and `_isSameMonth`.
  - Month fallback behavior prefers the last month with positive total if the current selected month has no data.
  - Dropdown options include positive-total months, or all returned months if no month has positive total, plus the selected month.
- Known gaps:
  - KPI/quick insight formatting still lives in widgets and can be considered in a later package if needed.

## Implementation Steps

1. Add `lib/features/dashboard/dashboard_view_model.dart`.
2. Move Dashboard month list and fallback selection rules into the view model.
3. Update `dashboard_view.dart` to consume the view model while preserving UI behavior.
4. Add `test/features/dashboard/dashboard_view_model_test.dart`.
5. Run formatter, focused Dashboard tests, analyzer, and full test suite.
6. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `lib/features/dashboard/dashboard_view.dart`
- `lib/features/dashboard/dashboard_view_model.dart`
- `test/features/dashboard/dashboard_view_model_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_7_dashboard_view_model.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Selected-month fallback changes and dashboard opens on a different month. | Add unit tests for positive-total, zero-total, and missing-selected-month cases. |
| View model starts depending on Flutter/l10n too early. | Keep it pure Dart and only use domain `MonthlyTotal`. |
| Widget behavior changes while wiring the model. | Run existing Dashboard widget smoke and full tests. |

## Tests And Checks

- [x] `dart format lib/features/dashboard/dashboard_view.dart lib/features/dashboard/dashboard_view_model.dart test/features/dashboard/dashboard_view_model_test.dart`
- [x] `flutter test test/features/dashboard/dashboard_view_model_test.dart test/features/dashboard/dashboard_view_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Dashboard month-selection mapping lives in `DashboardViewModel`.
- [x] Dashboard UI behavior is unchanged.
- [x] Focused view model tests pass.
- [x] Existing Dashboard widget smoke test passes.
- [x] Analyzer and full tests pass or any existing unrelated failures are documented.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-05
- Tests run:
  - `dart format lib/features/dashboard/dashboard_view.dart lib/features/dashboard/dashboard_view_model.dart test/features/dashboard/dashboard_view_model_test.dart`
  - `flutter test test/features/dashboard/dashboard_view_model_test.dart test/features/dashboard/dashboard_view_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Start Phase 7 with a narrow pure Dart Dashboard view model instead of broad presentation restructuring.
  - Keep currency/date localization in widgets for now because changing formatter ownership would broaden the package.
  - Keep selected-month provider ownership unchanged.
- Follow-ups:
  - Create a separate sub-plan before extracting `MonthViewModel`.
  - Consider KPI/quick-insight presentation mapping only if it removes meaningful widget complexity.
