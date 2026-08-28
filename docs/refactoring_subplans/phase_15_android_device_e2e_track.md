# Phase 15: Android Device E2E Automation Track

## Master Plan Link

- Master work package: `docs/framework_refactoring_plan.md`, Android E2E follow-up
- Strategy decision: `docs/refactoring_subplans/phase_10_e2e_ui_automation_strategy.md`
- Status: in progress
- Owner/agent: Codex
- Last updated: 2026-08-26

## Purpose

Maintain a dedicated, device-level test track for the Receipts UI on both Android emulators and an optionally connected physical Android device. This track owns only app-flow wiring and Android-runtime behavior; deterministic parsing, aggregates, privacy rules, and view-state rendering remain covered below the device layer.

This track prepared the educational native-E2E spike. Phase 16 subsequently
compared Patrol and Maestro on deliberately native Android scenarios and
selected Maestro. The goal was learning and an evidence-based framework
decision, not a business-coverage threshold.

## Current State Check

- Flutter `integration_test` is the approved default E2E harness. It starts the real app shell with Riverpod overrides, synthetic fixtures, native Android SQLite, and no network access.
- `integration_test/app_flow_test.dart` currently contains six passing Android journeys in one file: successful import, hash duplicate, JSON fallback, receipt-details navigation, persistence after app rebuild, and extraction failure.
- The local Android API 36 emulator run passed all six journeys on 2026-08-26. The manual GitHub Actions workflow provisions API 34.
- The existing PowerShell and shell helpers boot an emulator. A connected device is supported by the direct Flutter command and must be selected explicitly with its `flutter devices` identifier.
- A system viewer smoke for Open PDF is still manual because Flutter `integration_test` cannot reliably assert the external Android chooser/viewer.

## Scope

1. Keep a small, deterministic Flutter `integration_test` suite runnable on an emulator and a connected Android device.
2. Refactor the current monolithic integration test into focused flow files plus shared device-test support without changing coverage.
3. Establish a stable key contract for device tests; keys are behavior contracts, not styling selectors.
4. Record and automate only device-level checks that can be deterministic with synthetic fixtures.
5. Preserve a separate manual/native lane for system chooser, SAF, permission, and real PDF-extraction smoke checks.

## Non-goals

- Do not put emulator/device E2E into the fast PR or coverage gate.
- Do not use real receipts, NIP values, user paths, or network-dependent fixtures.
- Do not duplicate parser, aggregate, duplicate-detection, or privacy rules already asserted in unit/repository/use-case tests.
- Do not add Patrol, Maestro, an external device farm, or native picker automation in this package; the learning spike is a separately scoped follow-up after work package 15.1.
- Do not guarantee automation of the external document viewer.

## Target Layout

```text
integration_test/
├── support/
│   ├── device_test_harness.dart     # isolated native-SQLite setup and overrides
│   ├── app_driver.dart              # onboarding/navigation/import actions
│   └── waiters.dart                 # bounded deterministic widget waits
├── import_flow_test.dart            # success, duplicate, JSON fallback, safe failure
├── receipt_lifecycle_flow_test.dart # details and persistence after app rebuild
└── test_keys.dart                   # temporary location; move to a shared test-key contract
```

The exact split may use two or more flow files, but each test file must own a cohesive user journey and remain runnable through `flutter test integration_test`.

## Work Packages

### 15.1 Suite Structure and Stable Keys

Status: complete (2026-08-26).

1. Extract the repeated setup/teardown, bounded waiters, onboarding, navigation, and import actions from `app_flow_test.dart`.
2. Split the six existing journeys without weakening assertions or changing the native-SQLite configuration.
3. Move stable UI key definitions to a shared, production-owned contract (for example `lib/core/testing/`) only where the app exposes that key. Keep test-only helpers under `integration_test/support/`.
4. Replace only duplicated literal `ValueKey` uses in nearby widget tests; do not perform a broad key migration.

Definition of Done:

- [x] Each existing journey remains covered exactly once.
- [x] Tests do not share database state or router location.
- [x] No test waits through arbitrary fixed delays.

### 15.2 Device Execution Contract

Status: in progress. The emulator path is validated; connected-device evidence remains optional and pending a device.

1. Keep the current headless API 34 GitHub Actions workflow manual-only.
2. Document the same suite for a booted local emulator and a connected device, including explicit `-d <device-id>` selection.
3. Make result evidence reproducible: device/API, command, total tests, build duration, test duration, and failures/redacted logs.
4. Keep TLS/truststore instructions machine-local; do not commit certificates, truststores, or environment-specific paths.

Definition of Done:

- The suite can run on the documented emulator and any debug-capable connected Android device.
- CI and local-device runs use synthetic data and leave no sensitive data in logs or artifacts.

### 15.3 Native-Surface Decision Point

Before adding a native automation dependency, assess the gaps below:

| Surface | Default evidence | Automation decision |
| --- | --- | --- |
| Open PDF/source external chooser | Manual smoke on an emulator/device with a compatible viewer | Maestro follow-up only if release risk warrants repeatable automation |
| Storage Access Framework/file picker | Manual smoke with synthetic files | Maestro native smoke is available for approved synthetic-file flows |
| Runtime permissions/system settings | Manual smoke when such a feature is introduced | No work until a product feature depends on it |
| Native PDF extraction | Existing fake-backed E2E plus manual synthetic-PDF smoke | Maestro follow-up only if platform regressions cannot be diagnosed below E2E |

## Risks

| Risk | Mitigation |
| --- | --- |
| Device suite becomes flaky or slow. | Keep flows short, use bounded semantic waits, measure each run, and retain the manual workflow. |
| Test code hides routing/database leaks. | Reset router and isolated database before every journey; assert visible outcome states. |
| Keys couple tests to layout. | Expose keys only for stable user actions/statuses; do not key decorative widgets. |
| Physical devices differ from emulators. | Record device/API evidence and keep unsupported native surfaces as explicit manual smoke. |
| Sensitive receipt data leaks into evidence. | Use only synthetic fixtures and capture redacted technical outcomes. |

## Tests and Checks

- `flutter analyze`
- `flutter test`
- `flutter test integration_test -d emulator-5554`
- `flutter test integration_test -d <connected-device-id>` when a physical device is available
- Manual Open PDF/source smoke on a device with a compatible viewer when changing that feature

## Definition of Done for the Track

- [x] The six baseline journeys are split into maintainable focused flow files with shared support.
- [x] The stable key contract is documented and used by the device suite.
- [x] Emulator commands are documented and reproducible.
- [ ] Connected-device evidence is recorded when a physical device is available.
- [ ] The manual-only Android workflow stays outside the fast PR/coverage gate.
- [x] Native-only gaps have an explicit evidence path: Phase 16 selected Maestro for the document-picker boundary.
- [x] Master tracker and this sub-plan contain current run evidence and follow-up status.

## Checkpoint Evidence: Flutter E2E Foundation

- Completed on: 2026-08-26
- Device: local headless `emulator-5554`, Android API 36 Google APIs Play Store image (`it_api36`)
- Command: `flutter test integration_test -d emulator-5554 --reporter expanded`
- Result: passed, 6/6 journeys in 1 minute 49 seconds.
- Build/install: the two focused test libraries each produced a debug APK (~60.7 seconds and ~60.3 seconds); device execution itself completed by 1:49 total.
- Journeys: successful import with native SQLite, hash duplicate, JSON fallback, safe extraction error, receipt-details navigation, and persistence after app rebuild.
- Additional checks: `flutter analyze` passed; `test/features/import/import_view_test.dart` passed (6/6).
- Infrastructure decisions:
  - `tool/it_android.ps1` now hides the background emulator window and accepts an explicit `-SystemImage` value so local API availability does not change the API 34 CI default.
  - The local TLS truststore remains user-scoped and uncommitted.
- Phase 16 outcome (2026-08-28): `docs/refactoring_subplans/phase_16_native_e2e_framework_learning_spike.md` selected Maestro after two headless passes each for approved first-import and exact-duplicate flows. Physical-device evidence remains a separately scoped follow-up.

## Start Criteria

- Start with work package 15.1; it is behavior-preserving and does not need a physical device.
- Run work package 15.2 after the suite refactor on the available emulator/device.
- The learning spike is complete. A future physical-device or CI expansion must use a new small sub-plan; it must not make the choice depend on a business-volume threshold.
