# Phase 16: Native E2E Framework Learning Spike

## Master Plan Link

- Architecture: `docs/e2e_automation_architecture.md`
- Foundation: `docs/refactoring_subplans/phase_15_android_device_e2e_track.md`
- Status: planned
- Owner/agent: Codex
- Last updated: 2026-08-26

## Goal

Learn and make an evidence-based choice between Patrol and Maestro by implementing the same small Android native-surface scenario with each candidate. This is explicitly a learning investment; it does not require a larger business E2E backlog.

## Scope

- Implement Pilot A from the architecture document: open the real Android document picker from Import, cancel it, and assert a safe stable return to Receipts.
- Run each implementation on the same local emulator; run on a connected device if available.
- Record setup, commands, duration, selectors, failure diagnostics, privacy evidence, and scorecard results.
- Choose Patrol, Maestro, or neither for the project's native E2E lane.

## Non-goals

- Do not migrate the six existing Flutter `integration_test` journeys.
- Do not make either candidate a PR/coverage gate.
- Do not automate a real receipt import, OCR, parsing, aggregate behavior, or external viewer content.
- Do not commit user documents, device paths/URIs, secrets, or framework-generated secrets.
- Do not implement Pilot B unless Pilot A is stable and the user requests the follow-up.

## Preconditions

- [x] Flutter Android E2E foundation is split and passes 6/6 on a local emulator.
- [ ] Local emulator/device can display the Android system document picker.
- [ ] Candidate CLIs are available only during their respective pilot setup.

## Implementation Steps

1. Create a short Pilot A checklist and expected safe app state before choosing a tool.
2. Run the Patrol setup and a one-test Pilot A implementation in an isolated `patrol_test/` package area.
3. Run the Maestro setup and an equivalent one-flow Pilot A implementation in an isolated `maestro/` package area.
4. Execute both on the same Android image, repeat each local run once, and record results in the scorecard.
5. Trigger exactly one manual CI proof only for the stronger candidate if its local runs are stable.
6. Update this sub-plan, the architecture document, and master tracker with the chosen direction; remove the losing pilot only after the decision is documented.

## Affected Files

- `docs/e2e_automation_architecture.md`
- this sub-plan and `docs/framework_refactoring_plan.md`
- Candidate-only directories such as `patrol_test/` and `maestro/`
- `pubspec.yaml`, Android runner files, `.gitignore`, or GitHub workflow only when a candidate requires them
- App Semantics only if Maestro needs a durable selector for Pilot A

## Risks

| Risk | Mitigation |
| --- | --- |
| System picker UI differs by Android image. | Assert only picker visibility and cancellation, use the same image for comparison, record API/device. |
| Framework setup dominates the experiment. | Score setup explicitly; do not hide it as incidental cost. |
| Privacy regression through native diagnostics. | Use cancellation only, synthetic state, and redact reports/screenshots. |
| Both tools appear viable after one scenario. | Choose the smaller maintenance fit or keep both pilots until a second scenario is justified. |

## Tests and Checks

- Existing `flutter analyze` and `flutter test` remain green.
- Existing `flutter test integration_test -d <device-id>` remains unchanged and passing.
- Each candidate runs Pilot A twice on the same emulator/device.
- A manual native test must not emit a personal path, URI, NIP, receipt text, totals, or document contents.

## Definition of Done

- [ ] Equivalent Pilot A exists and is executed for Patrol and Maestro.
- [ ] Results are recorded with the architecture scorecard.
- [ ] A framework (or neither) is selected with explicit reasons.
- [ ] The selected tool has one manual CI proof, or the lack of CI proof is recorded as the decision blocker.
- [ ] Existing Flutter E2E remains the default deterministic device suite.
