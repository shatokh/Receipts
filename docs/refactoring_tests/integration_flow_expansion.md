# Integration Flow Expansion

## Status

- Status: complete
- Parent plan: `docs/refactoring_tests/testing_plan.md`, Package 5
- Related strategy: `docs/refactoring_subplans/phase_10_e2e_ui_automation_strategy.md`
- Last updated: 2026-08-26

## Scope

- Split or add focused Android `integration_test` flows for duplicate import, JSON fallback, receipt-details navigation, and persistence after an app rebuild.
- Preserve the current manual-only Android workflow.

## Non-goals

- Do not add Patrol, native file-picker automation, real PDF extraction, or network-dependent tests.
- Do not move emulator tests into the PR/coverage gate.

## Current State Check

- `integration_test/app_flow_test.dart` is being split from a single broad happy/error/lifecycle flow into focused device journeys using synthetic file and PDF extractor fakes.
- The baseline journeys are successful import with native SQLite and extraction failure. Duplicate, JSON fallback, details navigation, and persistence remain to be added as isolated journeys.
- On 2026-08-25 the local Android baseline initially failed before test execution because Maven/Google requests failed TLS certificate validation (`PKIX path building failed`). A user-scoped JBR truststore containing the local Avast HTTPS-inspection root certificate fixed the local Gradle run; this machine-specific setting is not stored in the repository.
- On 2026-08-26 the existing smoke flow reached the app and correctly waited for its import outcome. The pipeline returned `SqfliteFfiException`: `DatabaseHelper.configureForTesting` was selecting the host-only `sqflite_common_ffi` factory on the Android emulator. The integration setup now keeps the native sqflite driver while still using an isolated database name.
- The successful-import baseline passed on the Android emulator after the native-driver fix. A separate error-path test then revealed that the global `GoRouter` preserved `/import` between device tests; the integration setup resets it to `/onboarding` before each flow.

## Implementation Steps

1. Repair and validate the existing smoke baseline using targeted widget waits for asynchronous import outcomes.
2. Keep successful import and extraction failure as independent baseline device journeys; do not combine routing, lifecycle, and persistence assertions into one flow.
3. Extract shared deterministic setup/helpers from the existing flow only if needed to keep focused flows readable.
4. Add the four missing journeys with synthetic fixtures and stable keys.
5. Run the relevant Android emulator suite via `tool/it_android.ps1` or the manual GitHub workflow.
6. Record runtime and any emulator-specific issues in this plan and `README_TESTING.md` if commands change.

## Risks

| Risk | Mitigation |
| --- | --- |
| Emulator tests become slow or flaky. | Keep each journey focused, retain `pumpAndSettleSafe`/`waitForFinder`, and leave the workflow manual-only. |
| Flows duplicate lower-layer tests. | Assert wiring and journeys only; keep parser/aggregate rules in unit and repository tests. |

## Definition Of Done

- [x] Duplicate, JSON fallback, details, and persistence journeys are covered by focused device tests.
- [x] Existing smoke flow passes on the local Android emulator with a targeted wait for import outcomes.
- [x] Android workflow remains manual-only.
- [x] Manual emulator evidence is recorded.

## Validation Attempt

- Attempted on: 2026-08-25
- Device: local `emulator-5554` (Android API 36)
- Command: `flutter test integration_test -d emulator-5554`
- Result: build failed before test execution. Dependency metadata for `androidx.test.espresso:espresso-core` could not be fetched from Google/Maven because of a TLS certificate-chain validation error.
- Follow-up: repair the local Java/Gradle trust configuration or use a CI runner with a valid trust store, then run the existing smoke flow before adding the focused journeys.

- Attempted on: 2026-08-26
- Device: local `emulator-5554` (Android API 36)
- Command: `flutter test integration_test -d emulator-5554`, with the user-scoped Gradle truststore configured through `GRADLE_OPTS`.
- Result: passed. All six focused journeys passed: successful import with native SQLite, hash duplicate, JSON fallback, receipt details, persistence after app rebuild, and extraction failure. APK build took 59.9 seconds and the device tests took 22 seconds.
- Additional checks: `flutter analyze` passed; `flutter test` passed (93 tests); `dart run tool/test_with_coverage.dart --min-coverage=50` passed at 67.26% (2003/2978 lines).

## Smoke Baseline Repair

- Diagnosis: `pumpAndSettleSafe` may settle before the async picker/import future completes, so the test now waits for its own stable outcome keys. That exposed the actual Android failure: host-only FFI had been forced in device tests.
- Changed: success and error branches wait up to 20 seconds for their own stable keys, then assert exactly one badge. `DatabaseHelper.configureForTesting` now accepts `useFfi`; host tests retain FFI by default, while the Android integration setup passes `false`.
- Evidence: the complete focused Android suite passed on 2026-08-26. The test remains manual-only and is not part of the fast PR/coverage gate.
