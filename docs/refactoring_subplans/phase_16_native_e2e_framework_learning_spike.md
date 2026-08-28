# Phase 16: Native E2E Framework Learning Spike

## Master Plan Link

- Architecture: `docs/e2e_automation_architecture.md`
- Foundation: `docs/refactoring_subplans/phase_15_android_device_e2e_track.md`
- Status: complete
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
| `phase_16e_dual_framework_redacted_pdf_pilots.md` | complete | Maestro passed each safe native-import scenario twice and was selected as the primary native Android E2E framework. Patrol's JUnit selection-result limitation is documented; no Patrol-specific app seam is justified. |

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
- [x] Candidate CLIs were available for their respective pilot setup.

## Coordination Definition of Done

- [x] Architecture, candidate boundary, scorecard, and privacy rules are documented.
- [x] Each implementation package has scope, non-goals, steps, affected files, risks, checks, and its own Definition of Done.
- [x] Phase 16b and 16c have comparable evidence and the framework decision is recorded.
- [x] Phase 16d is explicitly superseded with an evidence-backed reason.
- [x] Existing Flutter E2E remains the default deterministic device suite.

## Execution Baseline

All Phase 16a–16e comparison evidence ran only on the verified local `it_api36` / `emulator-5554` AVD. Headless runs are the recorded evidence; a visible window on that same AVD is debugging-only. Maestro is selected for the native Android E2E lane. Device diversity, physical-device proof, and CI promotion remain separate post-selection work rather than comparison evidence.

## Decision and Completion Evidence (2026-08-28)

Maestro is the primary framework for native Android E2E scenarios that cross
the Android system boundary, including the document picker. It passed both
privacy-safe native import scenarios (first import and exact duplicate) twice
on the fixed headless baseline using durable Semantics outcome identifiers.

Patrol is not adopted for this lane. Its picker-cancel pilot remains a useful
recorded learning result, but under the Patrol JUnit runner a selected
`file_picker` document does not complete the Dart future. The issue reproduced
after a fresh baseline launch and with a bounded async handoff. The team will
not change production import code or add a test-only seam merely to force
framework parity.

Flutter `integration_test` remains the deterministic app-flow suite. Maestro
native flows stay manual-only until a separately scoped physical-device and CI
follow-up supplies its own evidence.
