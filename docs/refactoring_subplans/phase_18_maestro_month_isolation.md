# Phase 18: Maestro Month-Isolation Coverage

## Master Plan Link

- Foundation: `docs/refactoring_subplans/phase_15_android_device_e2e_track.md`
- Framework decision: `docs/refactoring_subplans/phase_16_native_e2e_framework_learning_spike.md`
- Previous package: `docs/refactoring_subplans/phase_17_maestro_post_import_navigation.md`
- Architecture: `docs/e2e_automation_architecture.md`, Pilot C scenario 2
- Status: complete
- Last updated: 2026-08-29

## Goal

Prove through Maestro that two approved synthetic receipts imported through the
real Android document picker remain isolated in two different Month views.
The scenario must assert only safe structural states, never receipt contents,
dates, totals, merchants, paths, or URIs.

## Fixture Approval Gate

The owner approved the visual draft for `receipt_b` on 2026-08-29. The
generated PDF uses a deliberately different synthetic month and a longer
layout than `receipt_a`, contains no source objects or source metadata, and
has the same visual and structural privacy review recorded for `receipt_a`.

No original receipt, reversible redaction, source-to-derivative mapping, or
real transaction detail is an acceptable input for this package.

## Scope

- Generate and approve one safe `receipt_b.pdf` after the approval gate.
- Extend the fixture manifest with safe shape and intended-outcome metadata.
- Add a Maestro journey that imports `receipt_a` and `receipt_b` through the
  real picker, selects each Month option through non-visible stable identifiers,
  and confirms the structural one-receipt outcome in each view.
- Add only the minimal Month-picker and Month-outcome Semantics identifiers and
  focused widget tests required by the journey.
- Add a parser fixture contract for its synthetic date and representative
  category distribution; this is a unit-level parsing check, not a
  content-bearing Maestro assertion.
- Run the journey twice on headless `it_api36` / `emulator-5554` and update the
  cookbook, architecture, sub-plan, and master tracker.

## Non-goals

- Do not use real receipts or add more than one new fixture.
- Do not select a month using visible localized month text or assert a month
  label/date in Maestro.
- Do not assert receipt fields, totals, merchant names, paths, URIs, or PDF
  text.
- Do not add CI, a physical device, a new AVD, multi-file selection, or Patrol
  work.
- Do not change production import, parser, duplicate, or aggregate behavior
  solely for testability.

## Implementation Steps

1. Create a visual draft of a fully synthetic, longer `receipt_b` and obtain
   owner approval before committing any fixture.
2. Generate a fresh PDF with only approved synthetic data; visually and
   structurally review it, then update the manifest without recording contents.
3. Inspect the Month picker and add stable non-visible identifiers for opening
   it and choosing its first two rendered options; identifiers must be ordinal,
   not date-derived.
4. Expose a safe Month outcome identifier only when the selected month's list
   contains exactly one receipt; cover the contract with focused widget tests.
5. Add one Maestro flow: import A, import B, choose each Month option, and
   assert the one-receipt outcome after each selection.
6. Validate syntax; run focused widget tests, analyzer, full Flutter tests, and
   two headless Maestro runs. Record safe evidence and completion notes.

## Affected Files

- `assets/test/receipts/e2e/receipt_b.pdf` after approval
- `docs/e2e_receipt_fixture_manifest.md`
- `lib/app/app_test_keys.dart`
- `lib/features/month/widgets/month_picker.dart`
- `lib/features/month/widgets/receipt_list.dart`
- focused tests under `test/features/month/`
- `maestro/receipt_a_b_month_isolation.yaml`
- `maestro/README.md`
- `docs/e2e_automation_architecture.md`
- `docs/framework_refactoring_plan.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Fixture B contains recoverable or identifying source information. | Do not generate or commit it until the owner approves the visual draft; regenerate from synthetic values only. |
| Picker selectors depend on localized month labels. | Use only non-visible ordinal Semantics IDs for the first two rendered options. |
| Both Month screens are non-empty but not isolated. | Assert the safe exactly-one-receipt outcome after selecting each option. |
| The test contract becomes an accessibility/layout mirror. | Limit identifiers to picker open, two ordinal options, and one safe structural outcome. |

## Tests and Checks

- privacy visual and structural review before `git add`
- focused Month widget tests for new Semantics states
- `flutter analyze`
- `flutter test`
- `maestro check-syntax maestro/receipt_a_b_month_isolation.yaml`
- two headless Maestro executions on `it_api36` / `emulator-5554`
- `git diff --check` and final tracked-file/privacy review

## Definition of Done

- [x] Owner-approved, fully synthetic `receipt_b` is included in this change
  set with a safe manifest update.
- [x] One Maestro journey imports A and B through the real picker and proves
  one receipt in each selected Month without content-bearing selectors.
- [x] New Semantics contracts are minimal and covered by focused widget tests.
- [x] The flow passes twice on the verified headless baseline.
- [x] Cookbook, architecture, sub-plan, and master tracker record evidence and
  remaining follow-up work.

## Completion Evidence

- The owner approved the fully synthetic `receipt_b` visual draft on
  2026-08-29. The prepared asset and manifest contain no source receipt or
  source-to-derivative mapping.
- `test/receipt_b_fixture_parser_test.dart` covers the synthetic date and five
  representative category outcomes. The focused parser and Month widget tests
  passed.
- `maestro check-syntax maestro/receipt_a_b_month_isolation.yaml` passed.
- The scenario passed twice on headless `it_api36` / `emulator-5554` after
  staging the two approved synthetic files. Each run reset app state and
  asserted only non-content Semantics identifiers.
- `flutter analyze`, `flutter test`, and `git diff --check` passed.

## Follow-up Work

The selected manual Maestro lane now has the two-fixture baseline. Add another
scenario only through a new small sub-plan with an owner-approved synthetic
fixture or a narrowly defined existing-fixture behavior; physical-device and
CI evidence remain out of scope.
