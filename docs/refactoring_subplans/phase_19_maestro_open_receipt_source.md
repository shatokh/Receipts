# Phase 19: Maestro Open Receipt Source Smoke

## Master Plan Link

- Parent Android track: `docs/refactoring_subplans/phase_15_android_device_e2e_track.md`
- Feature contract: `docs/refactoring_subplans/phase_14_open_receipt_source.md`
- Framework decision: `docs/refactoring_subplans/phase_16_native_e2e_framework_learning_spike.md`
- Previous native package: `docs/refactoring_subplans/phase_18_maestro_month_isolation.md`
- Status: planned
- Last updated: 2026-08-29

## Goal

Prove that a receipt imported through the real Android document picker can open
its persisted synthetic source in Android's external PDF handler and return to
the intact Receipt Details screen after cancellation/back navigation.

## Current State Check

- Phase 14 already exposes the Open PDF action through an overrideable
  platform interface and Android `ACTION_VIEW` intent; it does not render or
  log the source URI.
- The selected `it_api36` / `emulator-5554` baseline passed a read-only
  `application/pdf` intent-resolution preflight on 2026-08-29.
- The app does not yet expose durable non-content Semantics identifiers for
  the first receipt row, Receipt Details state, or Open PDF action.

## Scope

- Reuse the approved synthetic `receipt_a.pdf`; do not add a fixture.
- Add only three durable Semantics identifiers: first rendered receipt row,
  Receipt Details screen, and Open PDF action.
- Add focused widget tests for those identifiers and their enabled source
  action state.
- Add one Maestro scenario: import A, open its first receipt, invoke Open PDF,
  press Android Back once, and confirm Receipt Details remains visible.
- Run syntax validation, focused tests, analyzer, full Flutter tests, and two
  headless Maestro executions on `it_api36` / `emulator-5554`.

## Non-goals

- Do not read, assert, screenshot, or report PDF viewer content.
- Do not assert viewer package names, visible PDF text, source names, source
  paths, URIs, merchant names, dates, or totals.
- Do not add an in-app PDF viewer, change source URI retention, alter Android
  intent behavior, or add a test-only app seam.
- Do not add a physical-device or CI lane, a new AVD, Patrol work, or a new
  fixture.

## Implementation Steps

1. Verify the plan against the current Receipt Details, source-opener, and
   list widgets; keep the preflight recorded without storing device reports.
2. Add the three minimal Semantics contracts and focused widget coverage.
3. Add `maestro/receipt_a_open_source.yaml` using only the existing safe
   import and structural selectors.
4. Stage the approved fixture, build/install the app, and run the scenario
   twice headlessly. A return to Receipt Details after a single Android Back
   is the sole proof that the external activity opened.
5. Update the Maestro cookbook, architecture evidence, this sub-plan, and
   the master tracker with safe completion evidence.

## Affected Files

- `lib/app/app_test_keys.dart`
- `lib/features/receipts/widgets/receipts_list.dart`
- `lib/features/receipt_details/widgets/receipt_details_content.dart`
- `lib/features/receipt_details/widgets/action_buttons.dart`
- focused tests under `test/features/receipts/` and
  `test/features/receipt_details/`
- `maestro/receipt_a_open_source.yaml`
- `maestro/README.md`
- `docs/e2e_automation_architecture.md`
- `docs/framework_refactoring_plan.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| A PDF handler is unavailable or changed on the test image. | Require intent-resolution preflight; do not interpret a missing handler as an app regression. |
| Viewer content appears in a report or assertion. | Assert only the return to the app's Receipt Details Semantics state after one Back action. |
| Selectors become a mirror of list layout. | Limit the list selector to the first rendered navigable receipt, plus the details state and durable Open PDF action. |
| The selected source is no longer accessible. | The app must show its existing generic safe error; investigate only through a separate bug diagnosis, without exposing the URI. |

## Tests and Checks

- read-only `application/pdf` intent-resolution preflight on the verified AVD
- focused Receipt List and Receipt Details widget tests
- `flutter analyze`
- `flutter test`
- `maestro check-syntax maestro/receipt_a_open_source.yaml`
- two headless Maestro runs on `it_api36` / `emulator-5554`
- `git diff --check` and final privacy review

## Definition of Done

- [ ] The flow imports the existing approved synthetic fixture and reaches
  Receipt Details without content-bearing selectors.
- [ ] One Android Back action after Open PDF returns to the intact Receipt
  Details screen in two headless runs.
- [ ] New Semantics identifiers are minimal and covered by focused tests.
- [ ] Cookbook, architecture, sub-plan, and master tracker contain only safe
  evidence and accurately record remaining follow-up work.
