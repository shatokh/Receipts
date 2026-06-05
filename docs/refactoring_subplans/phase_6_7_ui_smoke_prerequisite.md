# Phase 6/7: UI Smoke Coverage Prerequisite

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 6. Разделить крупные UI файлы` and `Этап 7. View models для экранов аналитики`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-02

## Scope

- Add minimal widget smoke tests before splitting large UI files.
- Cover Dashboard and Month first because they are the first UI split priorities.
- Use provider overrides with deterministic empty-state data.

## Non-goals

- Do not split UI files in this work package.
- Do not add golden tests yet.
- Do not validate full responsive layout.
- Do not change user-facing UI text.

## Current State Check

- Files inspected:
  - `lib/features/dashboard/dashboard_view.dart`
  - `lib/features/month/month_view.dart`
  - `lib/app/providers/data_query_providers.dart`
  - `test/helpers/test_environment.dart`
- Existing behavior confirmed:
  - Dashboard and Month consume Riverpod providers exported through `app/providers.dart`.
  - Both screens can be rendered with provider overrides for monthly totals, KPIs, month overview, and receipts by month.
- Known gaps:
  - No widget smoke tests exist for Dashboard or Month.

## Implementation Steps

1. Add a small widget pump helper local to the tests.
2. Add Dashboard empty-state smoke test.
3. Add Month empty-state smoke test.
4. Run focused widget tests and full suite.
5. Update completion notes and master plan tracker.

## Affected Files

- `test/features/dashboard/dashboard_view_test.dart`
- `test/features/month/month_view_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_6_7_ui_smoke_prerequisite.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Widget tests become brittle around exact localized copy. | Assert stable structural/localized title text only. |
| Provider override setup is noisy. | Keep helper local and minimal; extract later only if repeated. |

## Tests And Checks

- [x] `flutter test test/features/dashboard/dashboard_view_test.dart test/features/month/month_view_test.dart`
- [x] `flutter test`
- [x] `flutter analyze`

## Definition Of Done

- [x] Dashboard has a basic widget smoke test.
- [x] Month has a basic widget smoke test.
- [x] Focused widget tests pass.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-02
- Tests run:
  - `flutter test test/features/dashboard/dashboard_view_test.dart test/features/month/month_view_test.dart`
  - `flutter test`
  - `flutter analyze`
  - `dart run tool/test_with_coverage.dart --min-coverage=0`
- Coverage baseline after UI smoke prerequisite: 40.35% line coverage (870/2156 lines).
- Decisions made:
  - Add smoke widget tests with provider overrides instead of booting the full app/router.
  - Cover Dashboard and Month first because those are the first planned UI split targets.
  - Keep assertions focused on stable empty-state rendering.
- Follow-ups:
  - Add Receipts/Import/Settings smoke tests before splitting those specific screens.
  - Proceed to Dashboard UI split only in a separate sub-plan.
