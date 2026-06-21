# Phase 10: Analyze Deduplication

## Master Plan Link

- Master phase: follow-up from `docs/refactoring_subplans/phase_10_ci_quality_gates.md`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-21

## Scope

- Remove duplicate `flutter analyze` execution between GitHub Actions workflows.
- Keep `android-debug.yml` as the owner of fast analyze/unit/build feedback.
- Keep `sonar-scan.yml` focused on coverage generation and Sonar scan.
- Preserve existing triggers, Flutter version, coverage threshold, and manual dispatch behavior.

## Non-goals

- Do not merge workflows.
- Do not change coverage threshold.
- Do not change Android build, integration test, or emulator behavior.
- Do not change app code.

## Current State Check

- Files inspected:
  - `.github/workflows/android-debug.yml`
  - `.github/workflows/sonar-scan.yml`
  - `.github/workflows/integration_test.yml`
  - `docs/refactoring_subplans/phase_10_ci_quality_gates.md`
- Existing behavior confirmed:
  - `android-debug.yml` runs `flutter analyze`, `flutter test`, and debug APK build on `main` push/PR plus manual dispatch.
  - `sonar-scan.yml` also runs `flutter analyze` before coverage and Sonar scan.
  - Phase 10 recorded de-duplicating repeated analyze work as a follow-up.

## Implementation Steps

1. Remove the `Flutter analyze` step from `sonar-scan.yml`.
2. Keep `Flutter test with coverage` and `SonarQube Scan` unchanged.
3. Run diff/YAML sanity checks and local quality gates.
4. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `.github/workflows/sonar-scan.yml`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_10_analyze_deduplication.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Sonar manual dispatch no longer runs analyze. | Document analyze ownership in `android-debug.yml`; manual Sonar remains coverage/scan focused. |
| CI loses analyzer coverage if android-debug is disabled later. | Keep tracker evidence explicit so workflow ownership is visible. |
| YAML indentation breakage. | Use minimal removal and run diff checks. |

## Tests And Checks

- [x] `git diff --check`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Only `android-debug.yml` owns `flutter analyze`.
- [x] `sonar-scan.yml` still runs coverage helper and Sonar scan.
- [x] Local analyze/test checks pass.
- [x] Master plan tracker updated.

## Completion Notes

- Completed on: 2026-06-21
- Tests run:
  - `git diff --check`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Keep `flutter analyze` in `android-debug.yml` with unit tests and debug APK build.
  - Keep `sonar-scan.yml` focused on coverage helper execution and Sonar scan.
- Follow-ups:
  - None for this cleanup package.
