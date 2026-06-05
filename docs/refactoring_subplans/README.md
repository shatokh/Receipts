# Refactoring Subplans

This directory stores execution sub-plans for phases and major sections from `docs/framework_refactoring_plan.md`.

Do not implement a master-plan phase directly without a matching sub-plan. Each sub-plan should be small enough for one PR or one clearly reviewable work package.

## Naming

Use this pattern:

```text
phase_<number>_<short_slug>.md
```

Examples:

- `phase_0_privacy_logging_guardrails.md`
- `phase_1_provider_split.md`
- `phase_2_database_package_split.md`

## Template

```markdown
# Phase N: Short Title

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section ...
- Status: not started | planned | in progress | blocked | complete | superseded
- Owner/agent: Codex
- Last updated: YYYY-MM-DD

## Scope

- ...

## Non-goals

- ...

## Current State Check

- Files inspected:
- Existing behavior confirmed:
- Known gaps:

## Implementation Steps

1. ...
2. ...
3. ...

## Affected Files

- ...

## Risks

| Risk | Mitigation |
| --- | --- |
| ... | ... |

## Tests And Checks

- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] focused tests:

## Definition Of Done

- [ ] Behavior preserved or intentional behavior changes documented.
- [ ] Relevant tests/checks pass or known failures are documented.
- [ ] No raw receipt/file/user data in logs, telemetry, Sentry payloads, or test output.
- [ ] EN/RU/PL l10n updated when visible text changes.
- [ ] Master plan tracker updated.
- [ ] Follow-up work recorded.

## Completion Notes

- Completed on:
- Tests run:
- Decisions made:
- Follow-ups:
```
