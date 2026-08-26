# UI State Screen Matrices

## Status

- Status: complete
- Parent plan: `docs/refactoring_tests/testing_plan.md`, Package 4
- Last updated: 2026-08-25

## Scope

- Add deterministic widget-level loading, error, empty, and populated-state coverage for Dashboard, Month, Receipts, Receipt Details, and Settings/Language.
- Use Riverpod provider overrides and synthetic models only.

## Non-goals

- Do not invoke Android MethodChannels, file pickers, or a real emulator.
- Do not change production UI behavior or add product functionality.
- Do not duplicate parser, repository, or import persistence tests.

## Current State Check

- `ImportView` already has its complete rendering matrix in `ui_state_localization_coverage.md`.
- The remaining top-level screen tests are smoke-level: mostly one empty or happy-path case per screen.
- Existing views expose loading/error branches through `AsyncValue` and can be exercised with provider overrides.

## Implementation Steps

1. Add loading/error/populated assertions to existing Dashboard, Month, Receipts, and Receipt Details widget tests.
2. Add Settings and Language state/interaction coverage, including switching the local provider locale.
3. Run focused widget tests, analyzer, and the full fast test suite.
4. Record coverage and update the parent testing plan.

## Risks

| Risk | Mitigation |
| --- | --- |
| Tests become dependent on English copy. | Use widget types, stable keys, and localized text only when it is the contract. |
| Rendering tests accidentally use persistence/platform services. | Override every async provider and use synthetic data. |
| Locale state leaks across tests. | Reset `SharedPreferences` mock values for each Settings/Language test. |

## Definition Of Done

- [x] Remaining top-level screens have explicit state-matrix coverage appropriate to their async dependencies.
- [x] Tests stay emulator-free and deterministic.
- [x] Focused checks, analyzer, and fast suite pass.
- [x] Parent testing plan and completion notes are updated.

## Completion Notes

- Completed on: 2026-08-25
- Tests run:
  - `flutter test test/features/dashboard/dashboard_view_test.dart`
  - `flutter test test/features/month/month_view_test.dart test/features/receipts/receipts_view_test.dart test/features/receipt_details/receipt_details_view_test.dart test/features/settings/settings_view_test.dart`
  - `flutter analyze`
  - `flutter test` (93 tests)
  - `dart run tool/test_with_coverage.dart --min-coverage=50` (67.19%, 2001/2978 lines)
- Decisions made:
  - Keep deterministic rendering coverage below the emulator layer.
  - Use provider overrides and synthetic models; no platform services or real SQLite are exercised by these widget tests.
- Follow-ups:
  - Package 5: focused Android integration flows remain separate manual-only work.
