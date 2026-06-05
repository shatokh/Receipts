# Phase 6: Receipts UI Split

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 6. Разделить крупные UI файлы`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-04

## Scope

- Add minimal `ReceiptsView` widget smoke coverage before splitting the file.
- Split `lib/features/receipts/receipts_view.dart` into smaller feature-local widget files.
- Keep Receipts providers, route behavior, localized text, layout, formatting, filters, and empty/loading/error states unchanged.

## Non-goals

- Do not introduce `ReceiptsFilterState` or any view model in this work package.
- Do not redesign Receipts UI or change filtering behavior.
- Do not move receipts filter providers out of `app/providers` yet.
- Do not add or change user-facing localization strings.

## Current State Check

- Files inspected:
  - `lib/features/receipts/receipts_view.dart`
  - `lib/app/providers/ui_state_providers.dart`
  - `lib/app/providers/data_query_providers.dart`
  - `docs/refactoring_subplans/phase_6_month_ui_split.md`
- Existing behavior confirmed:
  - Receipts consumes shared UI state providers from `app/providers.dart`.
  - `filteredReceiptsProvider` and `monthlyTotalsProvider` can be overridden for a deterministic smoke test.
  - The file mixes screen orchestration with search/filter controls, empty state, and receipt list/tile rendering.
- Known gaps:
  - No `ReceiptsView` smoke test exists yet.
  - Filter-state relocation and view model extraction are later packages.

## Implementation Steps

1. Add `test/features/receipts/receipts_view_test.dart` for empty-state rendering with provider overrides.
2. Create `lib/features/receipts/widgets/` files for search/filter controls, empty state, and receipts list.
3. Move private widget implementations out of `receipts_view.dart` with behavior-preserving renames where import visibility requires public classes.
4. Keep filter-month option derivation in `receipts_view.dart`.
5. Run formatter, focused Receipts widget test, analyzer, and full test suite.
6. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `lib/features/receipts/receipts_view.dart`
- `lib/features/receipts/widgets/search_and_filters.dart`
- `lib/features/receipts/widgets/receipts_empty_state.dart`
- `lib/features/receipts/widgets/receipts_list.dart`
- `test/features/receipts/receipts_view_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_6_receipts_ui_split.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Filter controls change behavior during extraction. | Keep callback signatures and widget bodies unchanged; run focused widget smoke and full tests. |
| Receipt tile navigation breaks after extraction. | Keep `go_router` dependency local to list/tile widget and preserve route string. |
| Smoke test becomes too coupled to exact layout. | Assert stable title and empty-state localized text only. |

## Tests And Checks

- [x] `dart format lib/features/receipts/receipts_view.dart lib/features/receipts/widgets test/features/receipts/receipts_view_test.dart`
- [x] `flutter test test/features/receipts/receipts_view_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Receipts has a basic widget smoke test.
- [x] Receipts private widget implementations are moved to feature-local widget files.
- [x] Receipts behavior and localized strings are unchanged.
- [x] Focused Receipts widget test passes.
- [x] Analyzer and full tests pass or any existing unrelated failures are documented.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-04
- Tests run:
  - `dart format lib/features/receipts/receipts_view.dart lib/features/receipts/widgets test/features/receipts/receipts_view_test.dart`
  - `flutter test test/features/receipts/receipts_view_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Add a focused empty-state smoke test before extracting widgets because Receipts had no screen-level widget coverage.
  - Keep filter-month option derivation in `receipts_view.dart`.
  - Move rendering widgets into feature-local files with public wrapper names only where imports require them.
  - Keep filter-state relocation and view model extraction out of this package.
- Follow-ups:
  - Create a separate sub-plan before moving receipts filter providers closer to the feature.
  - Create a separate sub-plan before splitting `receipt_details_view.dart`.
