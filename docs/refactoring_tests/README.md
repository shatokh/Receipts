# Refactoring Test Plans

This directory stores testing and quality sub-plans that support refactoring work in `docs/framework_refactoring_plan.md`.

Use it for cross-cutting test strategy, coverage expansion, integration-test planning, and focused test-hardening packages. Keep each implementation sub-plan small enough for one PR or one clearly reviewable work package.

## Naming

Use descriptive names:

```text
testing_plan.md
<area>_test_expansion.md
<area>_integration_coverage.md
coverage_gate_<short_slug>.md
```

Examples:

- `testing_plan.md`
- `import_pipeline_test_expansion.md`
- `database_migration_test_expansion.md`
- `integration_import_flow_coverage.md`

## Expected Sections

New execution sub-plans should include:

- Scope
- Non-goals
- Current state check
- Affected files
- Risks and mitigations
- Tests and checks
- Definition of Done
- Completion notes

