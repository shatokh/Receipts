# Phase 10: CI Quality Gates

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 10. CI и quality gates`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-08

## Scope

- Inventory the current GitHub Actions quality gates.
- Unify Flutter SDK versions across workflows where there is no documented reason to diverge.
- Route coverage generation through the existing `tool/test_with_coverage.dart` helper so local and CI behavior use the same entry point.
- Keep coverage threshold conservative for this package; do not introduce a new failing gate without a separate decision.
- Update testing documentation to match the current manual integration workflow.

## Non-goals

- Do not add new third-party CI services.
- Do not make Android integration tests mandatory on every PR in this package.
- Do not change app code, database schema, import behavior, or user-facing strings.
- Do not raise coverage minimum above the current known achievable baseline in this package.

## Current State Check

- Files inspected:
  - `.github/workflows/android-debug.yml`
  - `.github/workflows/sonar-scan.yml`
  - `.github/workflows/integration_test.yml`
  - `tool/test_with_coverage.dart`
  - `README_TESTING.md`
  - `pubspec.yaml`
- Existing behavior confirmed:
  - `android-debug.yml` runs on push/PR to `main` and manual dispatch with Flutter `3.35.3`.
  - `sonar-scan.yml` runs on push/PR to `main` and manual dispatch with Flutter `3.35.3`, `flutter analyze`, and `flutter test --coverage`.
  - `integration_test.yml` is manual-only with Flutter `3.29.0`.
  - `tool/test_with_coverage.dart` runs `flutter test --coverage --test-randomize-ordering-seed=random` and enforces a configurable coverage minimum, defaulting to 70.
  - `README_TESTING.md` still describes integration tests as running on push/PR, which no longer matches the workflow trigger.
- Known gaps:
  - Fast unit/analyze/build and Sonar coverage are split across two workflows, causing duplicate `flutter analyze`.
  - Coverage minimum is not enforced by Sonar workflow today.
  - Integration workflow is intentionally manual but uses a different Flutter SDK version.

## Implementation Steps

1. Update `integration_test.yml` to use the same Flutter SDK version as the other workflows.
2. Update `sonar-scan.yml` to call `dart run tool/test_with_coverage.dart --min-coverage=0` instead of raw `flutter test --coverage`.
3. Update `README_TESTING.md` so CI integration test documentation matches the manual workflow.
4. Run lightweight checks for changed YAML/docs/scripts.
5. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `.github/workflows/integration_test.yml`
- `.github/workflows/sonar-scan.yml`
- `README_TESTING.md`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_10_ci_quality_gates.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Coverage gate unexpectedly blocks CI. | Use `--min-coverage=0` in this package and record threshold raise as a follow-up. |
| Integration workflow changes runtime behavior. | Only align Flutter SDK version; keep `workflow_dispatch` and emulator settings unchanged. |
| Docs drift from actual workflow triggers. | Update README based on current YAML, not assumed historical behavior. |

## Tests And Checks

- [x] `git diff --check`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Flutter SDK version is consistent across current workflows.
- [x] Sonar coverage generation uses the project coverage helper.
- [x] Integration testing docs reflect the current manual workflow.
- [x] Coverage threshold follow-up is recorded.
- [x] Master plan tracker updated.

## Completion Notes

- Completed on: 2026-06-08
- Tests run:
  - `git diff --check`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Align integration workflow Flutter SDK with the other workflows at `3.35.3`.
  - Keep Android integration tests manual-only through `workflow_dispatch`.
  - Use `dart run tool/test_with_coverage.dart --min-coverage=0` in Sonar so CI uses the project coverage helper without introducing a new failing threshold in this package.
- Follow-ups:
  - Choose and enforce a real CI coverage threshold in a separate package after reviewing the latest coverage baseline.
  - Consider de-duplicating repeated `flutter analyze` work between Android debug and Sonar workflows.
