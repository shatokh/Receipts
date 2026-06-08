# Phase 10: Coverage Threshold Decision

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 10. CI и quality gates`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-08

## Scope

- Measure the current unit/widget test coverage baseline with the project coverage helper.
- Replace the temporary `--min-coverage=0` Sonar workflow threshold with a conservative threshold that should pass on the current suite.
- Keep the threshold intentionally below the measured baseline to avoid flaky CI failures from small line-count changes.
- Record the measured baseline and future threshold follow-up.

## Non-goals

- Do not add new tests solely to raise coverage in this package.
- Do not make integration tests part of coverage.
- Do not change app behavior or production code.
- Do not set the long-term 70-75% target yet unless the current baseline supports it.

## Current State Check

- Files inspected:
  - `.github/workflows/sonar-scan.yml`
  - `tool/test_with_coverage.dart`
  - `docs/refactoring_subplans/phase_10_ci_quality_gates.md`
- Existing behavior confirmed:
  - Sonar workflow now uses `dart run tool/test_with_coverage.dart --min-coverage=0`.
  - Coverage helper defaults to 70 if no explicit threshold is provided.
  - Phase 10 closeout recorded choosing a real threshold as follow-up.

## Implementation Steps

1. Run `dart run tool/test_with_coverage.dart --min-coverage=0`.
2. Choose a conservative CI threshold below the measured baseline.
3. Update `.github/workflows/sonar-scan.yml`.
4. Run the coverage helper with the chosen threshold.
5. Run `flutter analyze` and `flutter test`.
6. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `.github/workflows/sonar-scan.yml`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_10_coverage_threshold.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| New threshold blocks CI after small unrelated changes. | Set threshold below measured baseline and document future incremental raises. |
| Coverage helper runtime slows local iteration. | Only Sonar coverage job uses the gate; fast Android debug workflow still runs plain `flutter test`. |
| Baseline is too low for long-term quality target. | Record baseline and defer test expansion to focused packages. |

## Tests And Checks

- [x] `dart run tool/test_with_coverage.dart --min-coverage=0`
- [x] `dart run tool/test_with_coverage.dart --min-coverage=50`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Current coverage baseline is recorded.
- [x] Sonar workflow uses a conservative non-zero coverage threshold.
- [x] Coverage helper passes with the chosen threshold.
- [x] Analyzer and full tests pass.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-08
- Tests run:
  - `dart run tool/test_with_coverage.dart --min-coverage=0`
  - `dart run tool/test_with_coverage.dart --min-coverage=50`
  - `flutter analyze`
  - `flutter test`
- Coverage baseline:
  - 51.05% line coverage, 1366/2676 lines.
- Decisions made:
  - Set Sonar workflow gate to `--min-coverage=50`, below the measured 51.05% baseline.
- Follow-ups:
  - Raise the gate gradually after focused test expansion; do not jump to the long-term 70-75% target until the suite supports it.
