# Phase 6: Settings UI Split

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 6. Разделить крупные UI файлы`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-05

## Scope

- Add minimal `SettingsView` widget smoke coverage before splitting the file.
- Split `lib/features/settings/settings_view.dart` into smaller feature-local widget files.
- Keep Settings providers, route behavior, localized text, layout, toggles, snackbars, clear-data dialog placeholder, and debug log path rendering unchanged.

## Non-goals

- Do not implement clear-all-data behavior in this work package.
- Do not redesign Settings UI.
- Do not move settings providers or locale controller.
- Do not add or change user-facing localization strings.

## Current State Check

- Files inspected:
  - `lib/features/settings/settings_view.dart`
  - `lib/app/providers/settings_providers.dart`
  - `lib/core/localization/locale_controller.dart`
  - `lib/data/repositories/settings_repository.dart`
- Existing behavior confirmed:
  - Settings consumes `sentryEnabledProvider`, `devLoggingEnabledProvider`, `errorLogPathProvider`, and `localeProvider`.
  - The file mixes screen orchestration with language, crash-reporting, about/privacy, debug logging, clear-data dialog, and section rendering.
  - Clear-all-data remains a placeholder snackbar.
- Known gaps:
  - No `SettingsView` smoke test exists yet.
  - Clear-data behavior and settings provider relocation are later packages.

## Implementation Steps

1. Add `test/features/settings/settings_view_test.dart` for basic rendering with provider overrides.
2. Create `lib/features/settings/widgets/` files for section wrapper and individual settings sections.
3. Move private widget implementations and section UI out of `settings_view.dart`.
4. Keep provider reads and callbacks in `settings_view.dart` unless moving them is purely mechanical.
5. Run formatter, focused Settings widget test, analyzer, and full test suite.
6. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `lib/features/settings/settings_view.dart`
- `lib/features/settings/widgets/settings_section.dart`
- `lib/features/settings/widgets/language_settings_section.dart`
- `lib/features/settings/widgets/crash_reports_section.dart`
- `lib/features/settings/widgets/about_settings_section.dart`
- `lib/features/settings/widgets/debug_settings_section.dart`
- `test/features/settings/settings_view_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_6_settings_ui_split.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Toggle callbacks change behavior during extraction. | Keep callbacks wired from `SettingsView`; run focused widget smoke and full tests. |
| Clear-data dialog placeholder changes behavior. | Move dialog helper without changing text/actions/snackbar. |
| Test accidentally touches real preferences/path resolution. | Override settings providers and log path provider in widget test. |

## Tests And Checks

- [x] `dart format lib/features/settings/settings_view.dart lib/features/settings/widgets test/features/settings/settings_view_test.dart`
- [x] `flutter test test/features/settings/settings_view_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Settings has a basic widget smoke test.
- [x] Settings section implementations are moved to feature-local widget files.
- [x] Settings behavior and localized strings are unchanged.
- [x] Focused Settings widget test passes.
- [x] Analyzer and full tests pass or any existing unrelated failures are documented.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-05
- Tests run:
  - `dart format lib/features/settings/settings_view.dart lib/features/settings/widgets test/features/settings/settings_view_test.dart`
  - `flutter test test/features/settings/settings_view_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Add a focused smoke test before extracting sections because Settings had no screen-level widget coverage.
  - Keep provider reads and side-effect callbacks in `settings_view.dart`.
  - Move rendering sections into feature-local widget files.
  - Keep clear-all-data as the existing placeholder dialog/snackbar.
- Follow-ups:
  - Create a separate sub-plan before implementing clear-all-data behavior.
  - Create a separate sub-plan before moving settings providers or debug logging controls.
