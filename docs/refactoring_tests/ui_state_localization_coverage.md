# UI State And Localization Coverage

## Status

- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-23
- Parent plan: `docs/refactoring_tests/testing_plan.md`, Package 4
- Related master-plan item: `docs/refactoring_subplans/phase_10_e2e_ui_automation_strategy.md`

## Scope

- Expand fast widget coverage for UI states that should remain below the E2E layer.
- Start with `ImportView`, because import is the primary user flow and currently only loading state is covered.
- Use provider overrides and fake controllers; do not use Android emulator, file picker, MethodChannel, or real SQLite for rendering-only assertions.

## Non-goals

- Do not add Patrol.
- Do not change production UI behavior.
- Do not add visible strings or ARB entries unless a real UI gap requires it.
- Do not test parser/import persistence here; that belongs to import/use-case/repository tests.
- Do not make emulator integration tests part of this package.

## Current State Check

Files inspected:

- `lib/features/import/import_view.dart`
- `lib/features/import/import_controller.dart`
- `test/features/import/import_view_test.dart`
- `lib/domain/models/import_result.dart`

Existing behavior confirmed:

- `ImportView` renders loading, empty, and import history states from `importControllerProvider`.
- Status badges use stable keys:
  - `import_status_success`
  - `import_status_duplicate`
  - `import_status_error`
- Error entries render a retry button.
- Existing widget coverage only verifies loading state and absence of empty state underneath.

## Changes

ImportView widget tests added:

- Empty state.
- Loading state without empty state underneath.
- Successful import history item.
- Duplicate import history item.
- Error history item with retry action.
- Partial batch history with success, duplicate, and error entries.

Test harness changes:

- Added a local `_pumpImportView` helper with `ProviderScope`, localization delegates, and `MaterialApp`.
- Added `_SeededImportController` to render deterministic history entries without file picker, MethodChannel, import service, or SQLite.
- Kept status assertions on stable badge keys.

## Implementation Steps

1. Add a reusable ImportView test harness that wraps `ProviderScope`, localizations, and `MaterialApp`.
2. Add controller fakes for:
   - empty data state;
   - success/duplicate/error history;
   - partial batch history.
3. Assert status badges by key.
4. Assert user-safe messages render when supplied.
5. Assert sensitive source URI fragments do not appear as raw subtitle/error text unless intentionally used as a filename.
6. Run focused ImportView widget tests.
7. Run analyzer and full fast tests.
8. Update this document and `docs/refactoring_tests/testing_plan.md` with completion evidence.

## Affected Files

- `test/features/import/import_view_test.dart`
- `docs/refactoring_tests/ui_state_localization_coverage.md`
- `docs/refactoring_tests/testing_plan.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Widget tests become brittle by asserting every English label. | Prefer stable keys for status and only assert text when it is user-visible behavior. |
| Fake controller diverges from `ImportController` behavior. | Keep fake narrow: override `build`, `historyEntries`, and retry recording only. |
| Rendering-only tests accidentally exercise file picker/import pipeline. | Do not tap import button in these tests; keep file picker for integration tests. |
| Source URI assertions leak privacy-sensitive strings into UI contract. | Use synthetic URIs and assert safe messages, not raw private paths. |

## Tests And Checks

- [x] `dart format test/features/import/import_view_test.dart`
  - File formatted successfully.
  - Dart returned a telemetry access error for `%APPDATA%`, unrelated to file formatting.
- [x] `flutter test test/features/import/import_view_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`
- [x] `dart run tool/test_with_coverage.dart --min-coverage=50`

## Coverage Evidence

- Coverage after ImportView widget state expansion: 54.86% line coverage, 1621/2955 lines.
- Coverage run seed: `667593856`.
- Previous Package 3 baseline: 51.54% line coverage, 1523/2955 lines.

## Definition Of Done

- [x] ImportView empty, loading, success, duplicate, error, and partial result states are covered.
- [x] Error state renders retry affordance without invoking platform services.
- [x] Tests use localization delegates and stable keys.
- [x] Fast test suite still passes.
- [x] Follow-up UI screens are recorded.

## Completion Notes

- Completed on: 2026-06-23
- Tests run:
  - `flutter test test/features/import/import_view_test.dart`
  - `flutter analyze`
  - `flutter test`
  - `dart run tool/test_with_coverage.dart --min-coverage=50`
- Decisions made:
  - Keep ImportView rendering tests below E2E; do not tap the import button or invoke file picker in this package.
  - Use path-based synthetic URIs such as `asset:///sample.pdf` when testing filename extraction.
- Follow-ups:
  - Dashboard/Month/Receipts/ReceiptDetails/Settings state matrices.
