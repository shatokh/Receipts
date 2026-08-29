# Phase 15: Android E2E Track Reconciliation

## Master Plan Link

- Parent track: `docs/refactoring_subplans/phase_15_android_device_e2e_track.md`
- Framework decision: `docs/refactoring_subplans/phase_16_native_e2e_framework_learning_spike.md`
- Current native evidence: `docs/refactoring_subplans/phase_18_maestro_month_isolation.md`
- Status: complete
- Last updated: 2026-08-30

## Goal

Bring the active Phase 15 coordination document into line with the completed
framework decision and current native evidence. This is documentation-only:
it must make Maestro ownership, the manual GitHub Actions lane, and the
remaining physical-device boundary clear without changing test behavior.

## Scope

- Update Phase 15's current-state, scope, non-goals, native-surface decision,
  Definition of Done, and evidence to reflect Phase 16--18.
- Record that the existing GitHub Actions Flutter integration workflow remains
  `workflow_dispatch` only and outside the fast PR/coverage gate.
- State the remaining work precisely: a physical-device result requires a
  separately scoped follow-up; a new native Maestro scenario requires its own
  small sub-plan.
- Remove obsolete wording that treats the selected native framework as a
  future choice.

## Non-goals

- Do not change app code, test code, workflow behavior, emulator setup, or
  native E2E coverage.
- Do not add a physical-device, CI, device-farm, or new Maestro scenario.
- Do not reactivate Patrol or add a Patrol-specific test seam.

## Implementation Steps

1. Compare Phase 15 with `AGENTS.md`, the manual Android workflow, and the
   completed Phase 16--18 records.
2. Update the active track with only evidence that has already been recorded.
3. Add completion evidence and remaining follow-up boundaries here and in the
   master tracker.
4. Run a documentation diff check and confirm the worktree has no unrelated
   changes before handoff.

## Affected Files

- `docs/refactoring_subplans/phase_15_android_device_e2e_track.md`
- `docs/refactoring_subplans/phase_15_e2e_track_reconciliation.md`
- `docs/framework_refactoring_plan.md`
- `docs/e2e_automation_architecture.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Historical Patrol wording is mistaken for current support. | Mark it historical and state that Patrol is not a supported suite. |
| Documentation implies that physical-device evidence exists. | Leave the parent track in progress and name physical-device evidence as pending. |
| A manual GitHub workflow is mistaken for Maestro CI. | Distinguish the existing Flutter integration workflow from the manual Maestro lane. |

## Tests and Checks

- inspect `.github/workflows/integration_test.yml`
- inspect the current `AGENTS.md` Android E2E policy
- `git diff --check`

## Definition of Done

- [x] The active Phase 15 document identifies Maestro as the selected native
  lane and Patrol as unsupported outside diagnosis.
- [x] The existing Flutter integration workflow and the separate manual
  Maestro lane are clearly distinguished.
- [x] Remaining physical-device and additional-scenario work is accurately
  bounded.
- [x] The master tracker records this reconciliation and `git diff --check`
  passes.

## Completion Evidence

- `.github/workflows/integration_test.yml` remains `workflow_dispatch` only;
  it runs Flutter `integration_test`, not Maestro, and stays outside the fast
  PR and coverage gates.
- The parent track now points to the recorded Phase 16 decision and Phase 17--
  18 Maestro evidence, while preserving physical-device evidence as pending.
- Current Android E2E policy in `AGENTS.md` and the architecture record agree:
  Maestro is selected; Patrol is not a supported suite.
- `git diff --check` passed.

## Remaining Follow-up

- A physical-device result needs a new small sub-plan and a specific connected
  debug-capable device; it is not implied by emulator evidence.
- Phase 19 subsequently completed the Open receipt source / external-handler
  return smoke. Further native coverage requires a new small sub-plan and a
  concrete regression or release-risk rationale.
