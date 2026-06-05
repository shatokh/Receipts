# Phase 6: Dashboard UI Split

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 6. Разделить крупные UI файлы`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-04

## Scope

- Split `lib/features/dashboard/dashboard_view.dart` into smaller feature-local widget files.
- Keep Dashboard providers, route behavior, localized text, layout, formatting, and empty/loading/error states unchanged.
- Preserve the existing Dashboard widget smoke test.

## Non-goals

- Do not introduce `DashboardViewModel` in this work package.
- Do not redesign Dashboard UI or change chart/category/KPI behavior.
- Do not move selected-month state out of app providers yet.
- Do not add or change user-facing localization strings.

## Current State Check

- Files inspected:
  - `lib/features/dashboard/dashboard_view.dart`
  - `test/features/dashboard/dashboard_view_test.dart`
  - `docs/refactoring_subplans/phase_6_7_ui_smoke_prerequisite.md`
- Existing behavior confirmed:
  - Dashboard consumes shared providers from `app/providers.dart`.
  - Empty-state widget smoke coverage already exists.
  - The file mixes screen orchestration with KPI cards, chart, month dropdown, category bars, insight cards, and empty/error state widgets.
- Known gaps:
  - No golden or screenshot tests exist for Dashboard.
  - View model extraction is still a later Phase 7 package.

## Implementation Steps

1. Create `lib/features/dashboard/widgets/` files for KPI cards, monthly chart, month dropdown, top categories, quick insights, and dashboard states.
2. Move private widget implementations out of `dashboard_view.dart` with behavior-preserving renames where import visibility requires public classes.
3. Keep selected-month normalization and dropdown-month selection logic in `dashboard_view.dart`.
4. Run formatter, focused Dashboard widget test, analyzer, and full test suite.
5. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `lib/features/dashboard/dashboard_view.dart`
- `lib/features/dashboard/widgets/kpi_cards.dart`
- `lib/features/dashboard/widgets/monthly_chart.dart`
- `lib/features/dashboard/widgets/month_dropdown.dart`
- `lib/features/dashboard/widgets/top_categories_section.dart`
- `lib/features/dashboard/widgets/quick_insights.dart`
- `lib/features/dashboard/widgets/dashboard_states.dart`
- `test/features/dashboard/dashboard_view_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_6_dashboard_ui_split.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Mechanical move accidentally changes Dashboard rendering. | Keep code bodies unchanged except class names/imports; run focused widget smoke and full tests. |
| Import cycles through app providers or widgets. | Keep widgets depending only on provider barrel where needed; avoid widgets importing `dashboard_view.dart`. |
| UI split hides need for view model extraction. | Record view model work as Phase 7 follow-up, not part of this package. |

## Tests And Checks

- [x] `dart format lib/features/dashboard/dashboard_view.dart lib/features/dashboard/widgets test/features/dashboard/dashboard_view_test.dart`
- [x] `flutter test test/features/dashboard/dashboard_view_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Dashboard private widget implementations are moved to feature-local widget files.
- [x] Dashboard behavior and localized strings are unchanged.
- [x] Focused Dashboard widget test passes.
- [x] Analyzer and full tests pass or any existing unrelated failures are documented.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-04
- Tests run:
  - `dart format lib/features/dashboard/dashboard_view.dart lib/features/dashboard/widgets test/features/dashboard/dashboard_view_test.dart`
  - `flutter test test/features/dashboard/dashboard_view_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Keep Dashboard selected-month normalization and dropdown-month selection logic in `dashboard_view.dart`.
  - Move rendering widgets into feature-local files with public wrapper names only where imports require them.
  - Keep view model extraction out of this package so the split remains mechanical.
- Follow-ups:
  - Create a separate sub-plan before extracting `DashboardViewModel`.
  - Create a separate sub-plan before splitting `month_view.dart`.
