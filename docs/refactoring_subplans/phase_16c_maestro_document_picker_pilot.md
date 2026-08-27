# Phase 16c: Maestro Document Picker Pilot

## Master Plan Link

- Coordination: `docs/refactoring_subplans/phase_16_native_e2e_framework_learning_spike.md`
- Architecture: `docs/e2e_automation_architecture.md`, Pilot A
- Status: planned
- Last updated: 2026-08-26

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
2. Audit the Pilot A app controls for an existing durable Semantics contract; add the smallest non-visible semantic identifiers only if required.
3. Create an isolated Maestro flow that reaches and cancels the Android picker.
4. Run it twice on the same Android image used by the Patrol pilot.
5. Record the same scorecard evidence: setup, command, duration, selectors, diagnostics, and privacy behavior.

## Affected Files

- `maestro/` flow/configuration files
- `lib/` only for narrowly scoped Semantics identifiers
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

## Definition of Done

- [ ] Maestro Pilot A passes twice on the documented Android image.
- [ ] Any Semantics contract is minimal, durable, and localization-independent.
- [ ] Existing Flutter E2E still passes.
- [ ] Comparable scorecard evidence is recorded.
