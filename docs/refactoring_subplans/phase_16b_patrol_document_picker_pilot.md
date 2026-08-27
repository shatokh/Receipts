# Phase 16b: Patrol Document Picker Pilot

## Master Plan Link

- Coordination: `docs/refactoring_subplans/phase_16_native_e2e_framework_learning_spike.md`
- Architecture: `docs/e2e_automation_architecture.md`, Pilot A
- Status: planned
- Last updated: 2026-08-26

## Scope

- Add the minimum Patrol setup required for one Android-only native E2E test.
- Implement Pilot A: navigate to Import, open the real Android document picker, cancel it, and verify a safe stable return to Receipts.
- Run the test twice only on the verified local headless `it_api36` / `emulator-5554` baseline and record setup/runtime/reporting evidence for the scorecard.

## Non-goals

- Do not migrate the existing Flutter `integration_test` suite.
- Do not import a real document or assert picker-specific text, paths, or content.
- Do not make Patrol part of the fast PR/coverage gate.
- Do not implement Pilot C in this package.

## Implementation Steps

1. Read the current Patrol setup requirements and add only the required dev dependency, CLI configuration, native runner files, and generated-file ignores.
2. Create an isolated `patrol_test/` Pilot A test with stable in-app selectors and bounded native waits.
3. Start the app, invoke Import, verify the system picker is reached, cancel it, and assert the safe in-app state.
4. Run the test twice on the same Android image and record command, versions, duration, results, and redacted diagnostics.
5. Update the Phase 16 scorecard without selecting a winner yet.

## Affected Files

- `pubspec.yaml`, `pubspec.lock`, `.gitignore`
- `patrol_test/` and Patrol-required Android runner/configuration files
- `lib/` only if a durable, non-visible test selector is genuinely required
- Phase 16 evidence and architecture scorecard

## Risks

| Risk | Mitigation |
| --- | --- |
| Native runner setup changes Android build behavior. | Keep setup minimal; run existing Flutter E2E before and after. |
| Picker selectors vary by API image. | Assert picker arrival/cancellation, not vendor text or document contents. |
| Generated files or secrets enter Git. | Follow Patrol ignore rules and review staged files. |

## Tests and Checks

- `flutter analyze`
- `flutter test`
- Existing `flutter test integration_test -d <device-id>`
- Patrol Pilot A twice on the same emulator/device
- `git diff --check` and privacy review of report artifacts

## Definition of Done

- [ ] Patrol Pilot A passes twice on one documented Android image.
- [ ] Existing Flutter E2E still passes.
- [ ] Setup, duration, selectors, diagnostics, and privacy evidence are in the scorecard.
- [ ] Generated files/secrets are excluded from Git.
