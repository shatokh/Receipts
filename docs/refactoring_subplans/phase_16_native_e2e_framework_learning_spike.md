# Phase 16: Native E2E Framework Learning Spike

## Master Plan Link

- Architecture: `docs/e2e_automation_architecture.md`
- Foundation: `docs/refactoring_subplans/phase_15_android_device_e2e_track.md`
- Status: planned
- Owner/agent: Codex
- Last updated: 2026-08-26

## Goal

Learn and make an evidence-based choice between Patrol and Maestro. The broader Flutter/Android E2E landscape is recorded in the architecture document so that UI Automator and Appium are consciously deferred rather than forgotten. This is explicitly a learning investment; it does not require a larger business E2E backlog.

This document is the coordination plan, not an implementation PR. The work is split into the small sub-plans listed below.

## Work Package Map

| Package | Status | Purpose |
| --- | --- | --- |
| `phase_16a_e2e_receipt_fixture_corpus.md` | planned | Produce two safe real-format fixtures and their privacy manifest. |
| `phase_16b_patrol_document_picker_pilot.md` | planned | Implement and measure Patrol Pilot A. |
| `phase_16c_maestro_document_picker_pilot.md` | planned | Implement and measure Maestro Pilot A. |
| `phase_16d_selected_framework_real_receipt_pilot.md` | planned | Use the selected framework with the approved fixture corpus for Pilot C. |

Sequence: 16a can proceed alongside 16b/16c; 16d starts only after both the framework decision and fixture approval.

## Non-goals

- Do not treat this coordination plan as authorization to add both frameworks in one PR.
- Do not migrate the six existing Flutter `integration_test` journeys.
- Do not make either candidate a PR/coverage gate.
- Do not use raw fixture content in logs, failure output, screenshots, or reports. Pilot C asserts safe structural outcomes only; detailed parser checks stay in sanitized unit tests.
- Do not commit user documents, device paths/URIs, secrets, or framework-generated secrets.
- Do not implement Pilot B unless Pilot A is stable and the user requests the follow-up.

## Preconditions

- [x] Flutter Android E2E foundation is split and passes 6/6 on a local emulator.
- [x] Comparison execution baseline is fixed: local headless `it_api36` / `emulator-5554` (Android API 36, Google APIs Play Store image).
- [ ] Local emulator/device can display the Android system document picker.
- [ ] Two safe-to-commit, redacted real-format fixtures from different months are available with a privacy-reviewed manifest.
- [ ] Candidate CLIs are available only during their respective pilot setup.

## Coordination Definition of Done

- [x] Architecture, candidate boundary, scorecard, and privacy rules are documented.
- [x] Each implementation package has scope, non-goals, steps, affected files, risks, checks, and its own Definition of Done.
- [ ] Phase 16b and 16c have comparable evidence and a framework decision is recorded.
- [ ] Phase 16d is completed or explicitly superseded with an evidence-backed reason.
- [ ] Existing Flutter E2E remains the default deterministic device suite.

## Execution Baseline

All Phase 16a–16d work runs only on the verified local headless AVD `it_api36` / `emulator-5554` until Patrol versus Maestro is decided. Do not substitute a physical device, a different AVD, CI, or a device farm during this comparison. Device diversity is a post-selection follow-up, not comparison evidence.
