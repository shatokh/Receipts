# Phase 16b: Patrol Document Picker Pilot

## Master Plan Link

- Coordination: `docs/refactoring_subplans/phase_16_native_e2e_framework_learning_spike.md`
- Architecture: `docs/e2e_automation_architecture.md`, Pilot A
- Status: complete
- Last updated: 2026-08-27

## Scope

- Add the minimum Patrol setup required for one Android-only native E2E test.
- Implement Pilot A: navigate to Import, open the real Android document picker, cancel it, and verify a safe stable return to Import.
- Run the test twice headlessly on the verified local `it_api36` / `emulator-5554` baseline and record setup/runtime/reporting evidence for the scorecard. A visible window on that same AVD is allowed only for interactive debugging.

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
- `patrol_test/` (including its console cookbook) and Patrol-required Android runner/configuration files
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

## Execution Evidence (2026-08-27)

- Environment: verified local headless `it_api36` on `emulator-5554`; Patrol CLI 4.7.0 and package 4.9.0.
- Setup completed: the Patrol dev dependency/configuration, Android runner, Android Test Orchestrator, and generated-file ignores are present.
- The Pilot A Dart test reaches the native `pressBack` action after invoking the real `file_picker` flow and returns to the stable Import action. The native action and the Dart assertion both report success (1/1).
- A direct, content-free Android `ACTION_OPEN_DOCUMENT` probe on this AVD resolves to `com.google.android.documentsui`, so the verified image provides the expected system picker.
- Native DocumentsUI visibility inspection is not reliable on this API 36 image under Patrol instrumentation: package-based lookup timed out and the system reported an ANR. The committed test therefore verifies the safe native Back round-trip through the durable in-app outcome rather than picker text or file-tree nodes.
- Host runner diagnosis: every `patrol test` attempt exits with code 1 even after the Dart test succeeds. Android Gradle Unified Test Platform records the native test as `PASSED`, then fails its local result-listener gRPC/TLS channel. The listener uses temporary mutually authenticated certificates on `localhost`; applying the host download truststore does not change that private trust relationship. Avast is active on this host, and its TLS interception is the most likely environmental cause, but its logs did not provide a conclusive event.
- Temporary execution repair: `tool/run_patrol_android.ps1` builds the selected test with `patrol build android`, installs the resulting APKs, and starts the exact `PatrolJUnitRunner` through `adb`. It fails on non-zero instrumentation status, JUnit failure markers, or a missing JUnit success marker, so it does not reclassify a report artifact as a green run. It deliberately remains manual-only and scoped to the verified AVD.
- Confirmation runs: the helper completed twice with exit code 0 and JUnit `OK (1 test)`. After the first build, each warm build plus test run took about 30 seconds; the native JUnit portion took about 12 seconds. The Phase 16 architecture scorecard records the evidence without assigning a comparative score before Maestro Pilot A.
- Regression check: the existing Flutter Android `integration_test` suite still passes 6/6 on the same AVD in 1:49 after the Patrol runner was added.
- Project checks after the runner repair: `flutter analyze` completed with no issues and `flutter test` completed with 104 passing tests.
- Runtime-rule follow-up: start the comparison AVD with `-no-snapshot`, wait for both ADB `device` state and `sys.boot_completed=1`, and treat snapshot/update-check warnings as non-blocking only after that readiness check. The visual `patrol develop` session requires an interactive TTY; Android dependency TLS uses an ignored local truststore supplied through `RECEIPTS_GRADLE_TRUST_STORE`, never a committed certificate or security-product change.
- Developer handoff: `patrol_test/README.md` records the copyable console sequence for environment setup, AVD readiness, deterministic JUnit execution, visual `develop`, and safe diagnostics.
- No receipt was selected, read, logged, or used as an assertion. Generated bundles and report artifacts remain ignored/untracked.

## Runner Constraint And Next Experiment

`patrol test` itself remains unusable on this host because its UTP result-listener process returns code 1 after a passed test. The project helper preserves JUnit's real pass/fail result without suppressing failures, so it unblocks the learning pilot but is not evidence that the UTP defect is fixed. The next bounded environment experiment is an Avast localhost/mTLS exclusion or temporary HTTPS-inspection disablement, followed by the official `patrol test` command; do not change global security settings without explicit approval.

## Definition of Done

- [x] Patrol Pilot A passes twice through the project helper on the verified AVD; the official CLI defect is recorded separately. (2026-08-27; two JUnit `OK (1 test)` runs.)
- [x] Existing Flutter E2E still passes. (6/6 on `it_api36` in 1:49 on 2026-08-27.)
- [x] Setup, duration, selectors, diagnostics, and privacy evidence are in the scorecard.
- [x] Generated files/secrets are excluded from Git. (`test_bundle.dart` and `.patrol.env` are ignored; no secret or receipt content was created.)
