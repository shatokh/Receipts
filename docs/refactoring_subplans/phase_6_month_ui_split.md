# Phase 6: Month UI Split

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 6. Разделить крупные UI файлы`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-04

## Scope

- Split `lib/features/month/month_view.dart` into smaller feature-local widget files.
- Keep Month providers, route behavior, localized text, layout, formatting, and empty/loading/error states unchanged.
- Preserve the existing Month widget smoke test.

## Non-goals

- Do not introduce `MonthViewModel` in this work package.
- Do not redesign Month UI or change category/receipt list behavior.
- Do not move selected-month state out of app providers yet.
- Do not add or change user-facing localization strings.

## Current State Check

- Files inspected:
  - `lib/features/month/month_view.dart`
  - `test/features/month/month_view_test.dart`
  - `docs/refactoring_subplans/phase_6_dashboard_ui_split.md`
- Existing behavior confirmed:
  - Month consumes shared providers from `app/providers.dart`.
  - Empty-state widget smoke coverage already exists.
  - The file mixes screen orchestration with month picker, category breakdown, metric cards, and receipt tiles.
- Known gaps:
  - No golden or screenshot tests exist for Month.
  - View model extraction is still a later Phase 7 package.

## Implementation Steps

1. Create `lib/features/month/widgets/` files for month picker, category breakdown, metric card, and receipt list.
2. Move private widget implementations out of `month_view.dart` with behavior-preserving renames where import visibility requires public classes.
3. Keep selected-month normalization and dropdown-month selection logic in `month_view.dart`.
4. Run formatter, focused Month widget test, analyzer, and full test suite.
5. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `lib/features/month/month_view.dart`
- `lib/features/month/widgets/month_picker.dart`
- `lib/features/month/widgets/category_breakdown.dart`
- `lib/features/month/widgets/metric_card.dart`
- `lib/features/month/widgets/receipt_list.dart`
- `test/features/month/month_view_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_6_month_ui_split.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Mechanical move accidentally changes Month rendering. | Keep code bodies unchanged except class names/imports; run focused widget smoke and full tests. |
| Navigation from receipt tile breaks after extraction. | Keep `go_router` dependency local to receipt tile widget and preserve route string. |
| UI split hides need for view model extraction. | Record view model work as Phase 7 follow-up, not part of this package. |

## Tests And Checks

- [x] `dart format lib/features/month/month_view.dart lib/features/month/widgets test/features/month/month_view_test.dart`
- [x] `flutter test test/features/month/month_view_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Month private widget implementations are moved to feature-local widget files.
- [x] Month behavior and localized strings are unchanged.
- [x] Focused Month widget test passes.
- [x] Analyzer and full tests pass or any existing unrelated failures are documented.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-04
- Tests run:
  - `dart format lib/features/month/month_view.dart lib/features/month/widgets test/features/month/month_view_test.dart`
  - `flutter test test/features/month/month_view_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Keep Month selected-month normalization and dropdown-month selection logic in `month_view.dart`.
  - Move rendering widgets into feature-local files with public wrapper names only where imports require them.
  - Keep view model extraction out of this package so the split remains mechanical.
- Follow-ups:
  - Create a separate sub-plan before extracting `MonthViewModel`.
  - Create a separate sub-plan before splitting `receipts_view.dart`.
