# Android E2E Automation Architecture

## Status and Purpose

Status: proposed architecture and learning-spike decision record.  
Related implementation plan: `docs/refactoring_subplans/phase_16_native_e2e_framework_learning_spike.md`.

Receipts already has a deterministic Flutter device suite. This document defines how that suite, native Android automation, and manual release smoke should coexist. It deliberately treats adoption of Patrol or Maestro as an educational, evidence-driven spike: one or two scenarios are sufficient to learn the tool and make a durable decision; business-flow volume is not a prerequisite.

## Current Baseline

- Fast PR confidence comes from unit, repository/use-case, parser, privacy, and widget tests.
- Flutter `integration_test` runs six synthetic, offline Android journeys on the real app shell and native SQLite.
- The suite is split into import and receipt-lifecycle flows and shares an Android harness, driver, bounded waiters, and `AppTestKeys`.
- Android device tests remain manual-only in GitHub Actions and outside the coverage gate.
- A local API 36 emulator run passed all six Flutter device journeys on 2026-08-26. The CI workflow keeps API 34 as its reproducible default.

## Architecture

```text
                         Fast feedback: every PR
 unit / repository / use-case / widget tests ─────── flutter test
              │
              ├── deterministic app-flow lane ────── Flutter integration_test
              │       • Dart + Riverpod overrides
              │       • synthetic receipts and native SQLite
              │       • emulator or connected device
              │
              ├── native-system lane ─────────────── Patrol or Maestro pilot
              │       • Android document picker / external chooser / permission
              │       • real device UI, synthetic files only
              │       • manual or scheduled, never a fast gate initially
              │
              └── release smoke lane ─────────────── explicit manual checklist
                      • viewer availability / OS variation / physical device
```

The lanes complement rather than replace one another. Rules and data integrity belong below E2E; device suites prove that the app is wired together; native automation proves only OS-bound behavior that Flutter cannot reach reliably.

## Contracts at the Boundaries

| Concern | Flutter device lane | Native-framework lane | Rule |
| --- | --- | --- | --- |
| App selection | `AppTestKeys` | Semantics identifiers/labels for Maestro; Flutter/native selectors for Patrol | Do not reuse decorative layout selectors. |
| Test data | Riverpod fakes and synthetic assets | Synthetic file placed intentionally on the emulator/device | Never use a personal receipt, NIP, URI, or path in fixtures or logs. |
| Persistence | Isolated `integration_test.db`, reset per journey | Dedicated test app data/reset procedure | Tests must not depend on execution order. |
| Assertions | Widget state plus bounded waiters | Visible app/system outcome only | Do not encode parser or aggregate rules twice. |
| Evidence | Flutter test output | Framework report, device/API, redacted failure screenshot if enabled | Keep artifacts free of receipt data. |

`AppTestKeys` intentionally remain a Flutter contract. They are not an accessibility API. If Maestro is piloted, add explicit `Semantics` identifiers only for durable user actions and outcomes; do not scrape visible English/Russian/Polish text or mirror every widget key.

## Candidate Roles

### Patrol — in-process Flutter plus native automation

Patrol uses Dart tests and extends Flutter-style testing with native-platform actions. That makes it a natural fit when a scenario begins with provider-controlled app setup and then needs to interact with Android UI such as a picker, permission dialog, notification, WebView, or external activity.

Expected project impact:

- add a `patrol` dev dependency and the Patrol CLI;
- add native runner/setup files required by Patrol;
- keep tests in a dedicated `patrol_test/` directory;
- ignore generated `test_bundle.dart` and any `.patrol.env` file;
- run through `patrol test`, independently of `flutter test`.

Strength: reuses Dart skills, Flutter finders, and app-level setup.  
Cost: adds a package, CLI, native test runner, generated output, and framework-specific maintenance.

### Maestro — external black-box device automation

Maestro drives the installed application from the Android presentation/accessibility layer. Its Flutter support uses the Semantics tree, and its Android runner can address system UI without adding a Flutter dependency or building a test-specific APK.

Expected project impact:

- install the Maestro CLI, keep flows as declarative files in a dedicated directory;
- add stable Semantics identifiers to app controls used by the pilot;
- build/install a normal debug APK and execute the flow against an emulator or connected device;
- keep environment/device setup outside the app source tree.

Strength: validates the user-visible product from outside Flutter and can exercise system UI with no Dart integration.  
Cost: a second language/runner, reduced access to Riverpod fakes, and an accessibility contract that needs deliberate maintenance.

## Framework-Neutral Pilot

The same Android scenario is implemented once with each candidate. It is small by design:

### Pilot A: cancel a real Android document-picker flow

1. Launch the debug app on an emulator or connected device.
2. Navigate to Import.
3. Tap Import and wait for the OS document picker.
4. Cancel/back out of the picker.
5. Assert that Receipts returns to a stable Import state without importing a receipt or exposing a raw URI/path.

Why this scenario:

- it crosses the exact Flutter/native boundary that the current suite intentionally fakes;
- it does not require a real receipt or selecting a document;
- it can expose selector, synchronization, runner, and reporting differences clearly.

### Pilot B: optional follow-up — external source viewer cancellation

Only attempt this after Pilot A passes. It requires a deliberately generated synthetic PDF and a compatible Android viewer. The flow opens the stored source through the system chooser, cancels it, and verifies the Receipts app remains stable. Do not treat the external viewer's content or availability as a product assertion.

## Decision Scorecard

Score each framework after running Pilot A (and Pilot B if attempted) on the same emulator. Use a 1–5 score and include short evidence, not impressions.

| Criterion | Weight | What to measure |
| --- | ---: | --- |
| Native-flow reachability | 30% | Can the real picker be opened and cancelled reliably? |
| Local developer experience | 20% | Setup steps, diagnostics, rerun speed, understandable failures. |
| CI feasibility | 15% | Can the manual GitHub workflow run it without secrets or hidden machine state? |
| Selector stability | 15% | Does it use a durable app contract rather than visual text/layout? |
| Privacy-safe evidence | 10% | Can logs/screenshots avoid receipt contents, paths, and URIs? |
| Maintenance fit | 10% | New dependencies, generated files, Android/Flutter upgrade burden. |

Decision rules:

- Choose Patrol if native reachability is comparable and the Dart/native integration reduces pilot complexity enough to justify its runner setup.
- Choose Maestro if black-box system control and Semantics selectors are clearly more stable or easier to run in the intended device/CI environment.
- Choose neither if the pilot is brittle, the manual smoke is sufficient, or the maintenance cost outweighs the learning and release value. Retain Flutter `integration_test` as the device baseline in every outcome.

## Execution and CI Policy

1. Keep `flutter test` as the fast PR and coverage gate.
2. Keep the existing Flutter Android integration workflow manual-only while execution time is measured.
3. Keep the pilot workflow manual-only; no new secret, cloud device farm, or scheduled job is part of the first spike.
4. Record framework version, Flutter version, Android API/device image, command, duration, outcome, and redacted artifacts in the Phase 16 sub-plan.
5. Do not promote a native framework into routine CI until at least two stable local runs and one successful manual CI run are documented.

## Sources

- [Flutter integration testing concepts](https://docs.flutter.dev/cookbook/testing/integration/introduction) — Flutter `integration_test` runs on device/emulator but cannot interact with native platform UI.
- [Flutter testing overview](https://docs.flutter.dev/testing/overview) — testing-layer guidance and Patrol as a native-UI option.
- [Patrol native automation overview](https://patrol.leancode.co/documentation/native/overview) and [installation guide](https://patrol.leancode.co/documentation) — native controls, CLI, and generated-file handling.
- [Maestro Flutter support](https://docs.maestro.dev/platform-support/flutter) and [Maestro Android setup](https://docs.maestro.dev/getting-started/build-and-install-your-app/android) — Semantics-based Flutter automation and device-level Android control.
