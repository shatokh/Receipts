# Phase 17: Maestro Post-Import Navigation Coverage

## Master Plan Link

- Foundation: `docs/refactoring_subplans/phase_15_android_device_e2e_track.md`
- Framework decision: `docs/refactoring_subplans/phase_16_native_e2e_framework_learning_spike.md`
- Architecture: `docs/e2e_automation_architecture.md`, Pilot C
- Status: complete
- Last updated: 2026-08-28

## Goal

Extend the selected Maestro native Android E2E lane beyond the safe import
status badge. Using the already approved synthetic `receipt_a` fixture, prove
that a successful real-picker import reaches the two user-visible application
destinations that consume persisted data: Receipts and the corresponding Month
view.

## Scope

- Add one Maestro journey which starts from a clean app state, selects the
  approved fixture through the real Android document picker, receives the safe
  import-success state, then verifies safe non-empty outcomes in Receipts and
  Month.
- Add the smallest durable, non-visible Semantics identifiers needed for those
  two post-import outcomes.
- Add focused widget tests for any new Semantics contract.
- Run the new Maestro flow twice on headless `it_api36` / `emulator-5554` with
  `-no-snapshot -no-window -gpu host` and record only privacy-safe evidence.
- Update the Maestro cookbook, architecture record, this sub-plan, and the
  master tracker with the outcome.

## Non-goals

- Do not add a second fixture, a real receipt, or a month-isolation journey;
  that requires a new privacy-reviewed fixture package.
- Do not inspect or assert merchant, date, amount, line items, paths, URIs, or
  raw PDF text.
- Do not replace the existing first-import or exact-duplicate flows.
- Do not add native E2E to the PR/coverage gate, CI, a physical device, or a
  different AVD.
- Do not add Patrol tests or alter production import behavior for tests.

## Current State Check

- Maestro is the selected native Android E2E framework; its document-picker
  cancel, first-import, and exact-duplicate flows each have recorded headless
  evidence on `it_api36`.
- `assets/test/receipts/e2e/receipt_a.pdf` is the sole approved synthetic
  fixture. No approved second fixture currently exists.
- The existing first-import flow ends at `import_status_success`; it does not
  yet prove the persisted receipt is visible in Receipts or Month.

## Implementation Steps

1. Inspect the current Receipts and Month UI states and their widget coverage
   to identify privacy-safe, durable post-import outcomes.
2. Add only the required `AppTestSemanticsIds` and Semantics wrappers; keep
   visible text/localization unchanged.
3. Add or update focused widget tests for these identifiers and their
   non-empty states.
4. Add a declarative Maestro post-import navigation flow using identifiers,
   never visible receipt fields or translated text.
5. Run syntax validation, the focused widget tests, and the Maestro flow twice
   on the fixed headless AVD after its bounded readiness check.
6. Record commands and redacted outcomes; update the architecture, cookbook,
   this plan, and master tracker. If a stable outcome is not available without
   exposing receipt content, stop and revise this sub-plan rather than adding a
   fragile layout selector.

## Affected Files

- `lib/app/app_test_keys.dart`
- focused widgets under `lib/features/receipts/` and `lib/features/month/`
- focused widget tests under `test/features/`
- `maestro/receipt_a_post_import_navigation.yaml`
- `maestro/README.md`
- `docs/e2e_automation_architecture.md`
- `docs/framework_refactoring_plan.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| A selector exposes receipt content or depends on localization. | Use a non-visible Semantics identifier that names only the safe UI state. |
| The import's selected month is not the currently active Month screen. | Navigate through the app's normal user action and assert only a safe non-empty Month outcome. |
| Android picker root chooser layout varies. | Reuse the fixed-baseline picker navigation already evidenced in the two existing flows; treat a layout change as Maestro maintenance, not an app regression. |
| New semantics become a broad test-only surface. | Add at most one outcome identifier per destination and cover it with focused widget tests. |

## Tests and Checks

- focused Receipts and Month widget tests for any new Semantics identifiers
- `flutter analyze`
- `flutter test`
- `maestro check-syntax maestro/receipt_a_post_import_navigation.yaml`
- two headless Maestro executions on `it_api36` / `emulator-5554`
- `git diff --check` and a final privacy review of names, assertions, and
  generated artifacts

## Definition of Done

- [x] The new flow proves successful native-picker import, a non-empty
  Receipts destination, and a non-empty Month destination without fixture
  content in selectors or output.
- [x] Only minimal, focused Semantics identifiers and widget tests are added.
- [x] The flow passes twice on the fixed headless baseline.
- [x] Existing import and duplicate Maestro flows remain documented and valid.
- [x] Architecture, cookbook, sub-plan, and master tracker record outcome and
  remaining follow-up work.

## Completion Evidence (2026-08-28)

- Added `receipt_a_post_import_navigation.yaml`. It completes a real Android
  document-picker import and asserts only `receipts_list` and `month_receipts`
  after the existing safe success outcome.
- Added four Semantics identifiers: two navigation actions and one non-empty
  outcome for each destination. No visible text, receipt field, path, URI, or
  fixture content is used as a selector.
- Maestro CLI 2.9.0 completed the new flow twice on the verified headless
  `it_api36` / `emulator-5554` baseline, launched with
  `-no-snapshot -no-window -gpu host`.
- Focused Receipts, Month, and scaffold widget tests passed; `flutter analyze`
  and the full `flutter test` suite passed.

## Remaining Follow-up

The next meaningful coverage expansion is a second, privacy-reviewed synthetic
fixture in a different month for month-isolation coverage. Physical-device,
CI, and different-AVD proof remain separate work packages.
