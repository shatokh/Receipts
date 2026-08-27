# Phase 16c: Maestro Document Picker Pilot

## Master Plan Link

- Coordination: `docs/refactoring_subplans/phase_16_native_e2e_framework_learning_spike.md`
- Architecture: `docs/e2e_automation_architecture.md`, Pilot A
- Status: complete
- Last updated: 2026-08-27

## Scope

- Add the minimum Maestro setup required for one Android black-box E2E flow.
- Implement the same Pilot A as Patrol: navigate to Import, open the real Android document picker, cancel it, and verify a safe stable return.
- Establish only the Semantics identifiers required by this flow, then run the scenario twice only on the verified local headless `it_api36` / `emulator-5554` baseline.

## Non-goals

- Do not add Maestro selectors for all application widgets.
- Do not migrate existing Flutter tests or introduce real receipt import in this package.
- Do not make Maestro a PR/coverage gate.
- Do not implement Pilot C before framework selection.

## Implementation Steps

1. Install/configure the Maestro CLI using the current official setup instructions.
2. Audit the Pilot A app controls for an existing durable Semantics contract; Flutter `Key`s are not exposed to Maestro, so add only three non-visible identifiers if required: onboarding start, Import navigation, and Import action.
3. Create an isolated Maestro flow that reaches and cancels the Android picker.
4. Run it twice on the same Android image used by the Patrol pilot.
5. Record the same scorecard evidence: setup, command, duration, selectors, diagnostics, and privacy behavior.

## Affected Files

- `maestro/` flow/configuration files
- `lib/app/app_test_keys.dart`, onboarding/import views, and main scaffold only for the three narrowly scoped Semantics identifiers
- `.gitignore` only if Maestro generates local-only files
- Phase 16 evidence and architecture scorecard

## Risks

| Risk | Mitigation |
| --- | --- |
| Semantics selectors are missing or localized text is brittle. | Add a stable identifier only to the Pilot A contract; do not select translated text. |
| External test flow depends on stale app state. | Reset app data and device state before every run. |
| System picker differs by image. | Use the same image as Patrol and assert only safe cancel behavior. |

## Tests and Checks

- `flutter analyze` if app Semantics changes
- `flutter test` for any changed widgets
- Existing `flutter test integration_test -d <device-id>`
- Maestro Pilot A twice on the same emulator/device
- `git diff --check` and privacy review of artifacts

## Current-State Verification (2026-08-27)

- The verified `it_api36` / `emulator-5554` AVD can display and cancel the Android document picker.
- Existing `AppTestKeys` are Flutter-only `ValueKey`s. Maestro's current Flutter support uses the Semantics tree and cannot target those keys, so the planned three `Semantics.identifier` values are necessary and sufficient for Pilot A.
- Maestro CLI 2.9.0 is installed only in the local user profile with anonymous
  analytics disabled. The repository contains one declarative flow and exactly
  three `Semantics.identifier` values: onboarding start, Import navigation,
  and Import action.

## Completion Evidence (2026-08-27)

- `flutter test test/features/import/import_view_test.dart`: passed (6 tests);
  the test proves the Import action's Semantics identifier.
- `flutter analyze`: passed with no issues.
- `maestro check-syntax maestro/document_picker_cancel.yaml`: passed.
- Headless `it_api36` / `emulator-5554`, launched with
  `-no-snapshot -no-window -gpu host`: the picker-cancel flow passed twice in
  about 24–50 seconds per run. Each run reset only app data, reached all three
  Semantics IDs, opened the real Android picker, pressed native Back, and
  asserted the Import action was visible after returning.
- A visible run on the same AVD also passed twice while diagnosing an Android
  System UI ANR. The root cause was a stale QEMU process plus headless startup
  without explicit `-gpu host`; visible runs are diagnostic-only and are not
  used as scorecard evidence.
- Maestro debug artifacts remain in the local user profile and are not
  committed. The flow contains no document selection, receipt content, URI,
  file path, screenshot, or report artifact.

## Definition of Done

- [x] Maestro Pilot A passes twice on the documented Android image.
- [x] Any Semantics contract is minimal, durable, and localization-independent.
- [x] Existing Flutter E2E remains the deterministic device baseline; it was
  previously verified 6/6 on this AVD and was not changed by this pilot.
- [x] Comparable scorecard evidence is recorded.
