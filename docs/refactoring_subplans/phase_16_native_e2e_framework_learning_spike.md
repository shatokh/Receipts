# Phase 16: Native E2E Framework Learning Spike

## Master Plan Link

- Architecture: `docs/e2e_automation_architecture.md`
- Foundation: `docs/refactoring_subplans/phase_15_android_device_e2e_track.md`
- Status: in progress
- Owner/agent: Codex
- Last updated: 2026-08-28

## Goal

Learn and make an evidence-based choice between Patrol and Maestro. The broader Flutter/Android E2E landscape is recorded in the architecture document so that UI Automator and Appium are consciously deferred rather than forgotten. This is explicitly a learning investment; it does not require a larger business E2E backlog.

This document is the coordination plan, not an implementation PR. The work is split into the small sub-plans listed below.

## Work Package Map

| Package | Status | Purpose |
| --- | --- | --- |
| `phase_16a_e2e_receipt_fixture_corpus.md` | superseded | Its privacy gate is folded into Phase 16e, which uses one approved derivative for two scenarios in both candidates. |
| `phase_16b_patrol_document_picker_pilot.md` | complete | Patrol Pilot A passed twice through the project JUnit helper; the host-only UTP runner constraint is documented. |
| `phase_16c_maestro_document_picker_pilot.md` | complete | Maestro Pilot A passed twice headlessly with explicit GPU host; the System UI ANR diagnostic and workaround are recorded. |
| `phase_16d_selected_framework_real_receipt_pilot.md` | superseded | Replaced because the team chose to run the next two scenarios in both Patrol and Maestro before selecting a framework. |
| `phase_16e_dual_framework_redacted_pdf_pilots.md` | blocked | Maestro passed each safe native-import scenario twice; Patrol's JUnit runner does not deliver the selected `file_picker` result to Dart. A separate decision is needed before adding a Patrol-specific seam. |

Sequence: 16a's privacy work is folded into 16e. Phase 16e starts only after
the owner approves an irreversible, redacted PDF derivative; it does not wait
for a framework decision.

## Non-goals

- Do not treat this coordination plan as authorization to add both frameworks in one PR.
- Do not migrate the six existing Flutter `integration_test` journeys.
- Do not make either candidate a PR/coverage gate.
- Do not use raw fixture content in logs, failure output, screenshots, or reports. Pilot C asserts safe structural outcomes only; detailed parser checks stay in sanitized unit tests.
- Do not commit user documents, device paths/URIs, secrets, or framework-generated secrets.
- Do not implement Pilot B unless Pilot A is stable and the user requests the follow-up.

## Preconditions

- [x] Flutter Android E2E foundation is split and passes 6/6 on a local emulator.
- [x] Comparison execution baseline is fixed: local `it_api36` / `emulator-5554` (Android API 36, Google APIs Play Store image); headless runs are evidence, while a visible window on that same AVD is debugging-only.
- [x] The verified local emulator can display the Android system document picker. (Observed during the visual Patrol develop session on 2026-08-27.)
- [x] One safe-to-commit, synthetic real-format fixture is available with a privacy-reviewed manifest.
- [ ] Candidate CLIs are available only during their respective pilot setup.

## Coordination Definition of Done

- [x] Architecture, candidate boundary, scorecard, and privacy rules are documented.
- [x] Each implementation package has scope, non-goals, steps, affected files, risks, checks, and its own Definition of Done.
- [ ] Phase 16b and 16c have comparable evidence and a framework decision is recorded.
- [ ] Phase 16d is completed or explicitly superseded with an evidence-backed reason.
- [ ] Existing Flutter E2E remains the default deterministic device suite.

## Execution Baseline

All Phase 16a–16e work runs only on the verified local `it_api36` / `emulator-5554` AVD until Patrol versus Maestro is decided. Use headless runs for scorecard evidence; a visible window on that same AVD is allowed only to observe or debug a scenario and does not replace a recorded run. Do not substitute a physical device, a different AVD, CI, or a device farm during this comparison. Device diversity is a post-selection follow-up, not comparison evidence.
