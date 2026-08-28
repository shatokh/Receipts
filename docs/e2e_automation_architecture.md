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

## Candidate Landscape

This is the full set of materially relevant choices for a Flutter application that needs Android emulator/physical-device E2E. It is not a catalog of every commercial recorder or BDD wrapper: products that only wrap one of the drivers below do not create a distinct automation capability and are evaluated through their underlying driver.

| Family | Candidate | How it sees Receipts | Native/system UI | Position for this project |
| --- | --- | --- | --- | --- |
| Flutter SDK | `integration_test` | In-process Dart widget tree and providers | No | Retain as the deterministic device baseline. |
| Flutter-native | Patrol | Dart/Flutter finders plus native platform automation | Yes | Tier-1 learning pilot. |
| Black-box mobile | Maestro | Android display/accessibility and Flutter Semantics | Yes | Tier-1 learning pilot. |
| Android native | UI Automator 2.4 | Android accessibility windows from Kotlin instrumented tests | Yes | Reviewed only; do not pilot in this learning package. |
| WebDriver/mobile | Appium 3 + UiAutomator2 | External Android accessibility/UI hierarchy | Yes | Reviewed only; reconsider if cross-language, external QA, or device-farm interoperability becomes a project need. |
| WebDriver/Flutter community | Appium Flutter Driver / Integration Driver | Dart VM/Flutter context, optionally Appium native context | Partial to yes depending on driver/context | Research-only until an Appium requirement exists; its setup and compatibility cost must beat Appium UiAutomator2. |
| Android in-app | Espresso | Android View hierarchy from Kotlin | Limited; system UI needs UI Automator | Not a primary Flutter E2E choice because Receipts is Flutter, not a View-based UI. |
| Legacy Flutter | `flutter_driver` | Dart VM extension | No | Do not adopt; Flutter directs projects to `integration_test`. |
| BDD wrappers | Cucumber/Gherkin, Robot Framework/AppiumLibrary | Delegates to Flutter, Appium, or another driver | Inherits underlying driver | Add only if a human-readable business-spec workflow becomes a separate team need. |
| Visual/no-code/cloud tools | recorders, image-coordinate tools, vendor test clouds | Pixels and/or the chosen underlying driver | Varies | Device providers or reporting layers, not the first in-repo automation framework. Evaluate after a driver is chosen. |

Deliberate exclusions:

- Detox is a React Native framework, not a Flutter Android E2E candidate.
- Compose UI testing is for Compose UI, not the Flutter widget tree.
- Robolectric is a JVM Android-test environment, not a real device/system-UI E2E framework.
- Appium, Android Gradle Managed Devices, Firebase Test Lab, BrowserStack, and similar services overlap only in part: the first is a driver framework; the rest are execution/device infrastructure.

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

### Android UI Automator — native Kotlin system-UI automation

UI Automator is Android's instrumented test framework for interacting with both user and system apps through accessibility windows. Modern UI Automator provides predicate finders, built-in waits, explicit app state control, multi-window support, screenshots, and reporting.

Expected project impact:

- add an `androidTest` Kotlin source set and UI Automator dependency;
- launch the Flutter APK as an external Android application and use stable Semantics/accessibility values for app assertions;
- run through Gradle/Android instrumentation rather than Dart;
- retain the test as Android-only and keep its scope to native surfaces.

Strength: official Android path with no third-party cross-platform runner; an excellent control case for Android native behavior.
Cost: Kotlin/Gradle test maintenance and no access to Riverpod test overrides or Flutter widget finders.

### Appium — WebDriver mobile automation

Appium 3 with the official UiAutomator2 driver is an external Android WebDriver stack. It is the strongest candidate when test authors need languages other than Dart/Kotlin, standard WebDriver tooling, or compatibility with an Appium-capable device farm. Flutter can expose Semantics identifiers as Android resource IDs for a release-style accessibility contract.

Two Flutter-specific Appium community drivers also exist. The older Flutter Driver route depends on the Dart VM/`flutter_driver` extension and a debug/profile app. The integration-driver route is community-maintained and adds another protocol layer. Neither should be the default before ordinary UiAutomator2 is measured against the actual native scenario.

Strength: broad language/tool/device-farm ecosystem and true outside-the-app automation.
Cost: Appium server, Node, driver/client setup, capabilities, and usually a separate test language; Flutter-specific drivers add compatibility risk.

### Espresso and wrappers — explicitly non-primary

Espresso is valuable for View-based Android apps but does not make Flutter's Dart widget tree a better E2E surface. Pairing it with UI Automator is possible, yet UI Automator alone covers the system-level behavior being evaluated here. BDD layers, Robot Framework, and recorders are not rejected permanently; they are deferred because they add authoring syntax or a vendor layer without solving a capability gap first.

## Framework-Neutral Pilot

The inventory is broad, but the hands-on spike deliberately compares only Patrol and Maestro. They represent the two architectural models the team wants to understand: Dart-integrated native automation and external black-box device automation. UI Automator and Appium are documented alternatives, not pilot implementations.

1. Run Pilot A for Patrol and Maestro on the same Android image.
2. Prepare one privacy-reviewed synthetic fixture for Pilot C; use it to compare one realistic import journey after Pilot A establishes native picker control.
3. Run Pilot C in both candidates only when the team explicitly wants a final tie-breaker.
4. Reconsider UI Automator or Appium only through a new sub-plan if Android-only Kotlin ownership, WebDriver, external QA, or a device farm becomes a concrete need.

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

### Pilot C: real-format receipt corpus through the native import path

Pilot C is a realistic-device suite, not a replacement for parser unit tests. It exercises the real Android document picker, native PDF text extraction, parser, SQLite persistence, and month-based UI wiring with a small curated corpus.

Minimum corpus before this pilot starts:

| Fixture | Shape | Date relationship | Required observable outcome |
| --- | --- | --- | --- |
| Receipt A | Short receipt with a small number of lines | One month | Imports once; appears in Receipts and its month screen. |
| Receipt B | Long receipt with many lines and page/length variation if available | A different month | Imports once; appears separately under its month and does not alter Receipt A's month view. |

The user may add more varied examples after the two-fixture baseline: multi-page receipts, different merchants/layouts, discount/VAT variants, and more months. Each new fixture must declare the narrowly scoped UI behavior it is intended to prove; do not add a document merely to increase fixture count.

Candidate E2E scenarios selected from the corpus:

1. Import Receipt A through the real picker, then verify a receipt is visible in the list and the relevant month contains data.
2. Import Receipt B in a different month, then switch between the two month views and verify the receipts remain separated by month.
3. Import Receipt A again and verify the safe duplicate outcome without adding a second receipt.
4. If the picker supports a deliberate multi-file selection on the target Android image, import A and B in one selection and verify a safe per-file result summary. This is optional until the platform behavior is proven stable.

Fixture privacy contract:

- Never commit an original user receipt. Commit only a deliberately redacted, licensed, or synthetic-realistic derivative after a manual privacy review.
- Remove or replace personal names, loyalty identifiers, payment fragments, addresses, NIP/tax IDs, barcodes/QR codes, order numbers, and source paths.
- Do not print raw PDF text, line items, merchant addresses, dates, totals, hashes, local paths, or content URIs in test names, assertions, failure output, screenshots, or reports.
- Keep expectations structural and privacy-safe: successful/duplicate state, receipt count, isolated month presence, and safe error state. Detailed parser field assertions belong to sanitized unit fixtures, not this native E2E lane.
- Record the provenance, redaction review, intended scenario, and month bucket under a fixture manifest that itself contains no sensitive data.

Pilot C becomes a Tier-1-native candidate only after the corpus passes privacy review and the owner confirms the fixture files are safe to commit. It may be implemented with the selected native framework or used as a manual release smoke during framework comparison.

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

### Pilot A evidence (not a framework decision)

| Framework | Verified environment | Outcome | Scorecard evidence |
| --- | --- | --- | --- |
| Patrol | Local headless `it_api36` / `emulator-5554`; Patrol CLI 4.7.0, package 4.9.0 | Two direct JUnit runs passed for picker cancel/return-to-Import. | Native `pressBack` and a durable `AppTestKeys.importButton` assertion passed; the AVD's `ACTION_OPEN_DOCUMENT` handler was confirmed separately without selecting a file. Warm build plus run was about 30 seconds. The official `patrol test` command still fails after a passed test because AGP/UTP cannot maintain its host-local mTLS result listener; `tool/run_patrol_android.ps1` preserves the same runner's JUnit pass/fail outcome. No real receipt, URI, path, picker text, or screenshot was used. The framework decision remains deferred until the planned Pilot C has approved fixtures. |
| Maestro | Local headless `it_api36` / `emulator-5554`; Maestro CLI 2.9.0 | Two direct CLI runs passed for picker cancel/return-to-Import. | Three explicit Flutter `Semantics.identifier` selectors reached onboarding start, Import navigation, and Import action; native Back returned safely from the real picker. Each run took about 24–50 seconds and reset only app data. On this host, headless launch requires `-no-window -gpu host`: without explicit GPU mode, a stale QEMU process and Android System UI ANR obscured the Flutter hierarchy. Anonymous CLI analytics were disabled, and no receipt, URI, path, picker text, screenshot, or report was committed. |

### Pilot C evidence (not a framework decision)

| Framework | Verified environment | Outcome | Scorecard evidence |
| --- | --- | --- | --- |
| Patrol | Fresh headless `it_api36` / `emulator-5554`; Patrol package 4.9.0 | Blocked | Native selectors opened Documents UI and selected the approved synthetic fixture, but the Android `file_picker` plugin's Dart future never completed under the Patrol JUnit runner. The behavior reproduced after a fresh headless launch and with a bounded real-async handoff. The existing cancel flow still passes, isolating the limitation to selection-result delivery. Do not add a production test hook solely to score this pilot. |
| Maestro | Headless `it_api36` / `emulator-5554`; Maestro CLI 2.9.0 | Passed twice | Both safe outcomes — first import and exact duplicate — completed twice through the real Android picker using durable Semantics outcome identifiers. The fixture contains only reviewed synthetic data; no device report or screenshot was committed. |

For future Appium consideration, record whether WebDriver language/device-farm interoperability is worth the server and client stack. For future UI Automator consideration, record whether Android-only Kotlin ownership is acceptable. These are documented alternatives, not hidden pilot requirements.

Decision rules:

- Choose Patrol if native reachability is comparable and Dart/native integration reduces pilot complexity enough to justify its runner setup.
- Choose Maestro if black-box system control and Semantics selectors are clearly more stable or easier to run in the intended device/CI environment.
- Reopen UI Automator only if an Android-only, official Kotlin test becomes preferable after the Patrol/Maestro decision.
- Reopen Appium UiAutomator2 only if external WebDriver, non-Dart/Kotlin test authors, or an Appium-compatible device farm becomes a deliberate project need.
- Choose neither if every pilot is brittle, the manual smoke is sufficient, or maintenance cost outweighs learning/release value. Retain Flutter `integration_test` as the device baseline in every outcome.

## Execution and CI Policy

1. Until the framework decision, run every Phase 16 pilot only on the verified local `it_api36` / `emulator-5554` AVD (Android API 36, Google APIs Play Store image). Record scorecard evidence from headless runs; a visible window on that same AVD is debugging-only.
2. Do not use a connected physical device, a different AVD, cloud device farm, scheduled job, or CI run for the comparison; changing the device would invalidate like-for-like scorecard evidence.
3. Keep `flutter test` as the fast PR and coverage gate.
4. Keep the existing Flutter Android integration workflow manual-only while execution time is measured.
5. Record framework version, Flutter version, AVD/image, command, duration, outcome, and redacted artifacts in the Phase 16 sub-plan.
6. After selection, plan physical-device and manual-CI proof as a separate follow-up; do not promote a native framework into routine CI before that evidence exists.

## Sources

- [Flutter integration testing concepts](https://docs.flutter.dev/cookbook/testing/integration/introduction) — Flutter `integration_test` runs on device/emulator but cannot interact with native platform UI.
- [Flutter testing overview](https://docs.flutter.dev/testing/overview) — testing-layer guidance and Patrol as a native-UI option.
- [Patrol native automation overview](https://patrol.leancode.co/documentation/native/overview) and [installation guide](https://patrol.leancode.co/documentation) — native controls, CLI, and generated-file handling.
- [Maestro Flutter support](https://docs.maestro.dev/platform-support/flutter) and [Maestro Android setup](https://docs.maestro.dev/getting-started/build-and-install-your-app/android) — Semantics-based Flutter automation and device-level Android control.
- [Android UI Automator](https://developer.android.com/training/testing/other-components/ui-automator) — Android accessibility-window and system-app automation.
- [Appium UiAutomator2 quickstart](https://appium.io/docs/en/3.3/quickstart/uiauto2-driver/) and [Appium Flutter driver](https://github.com/appium/appium-flutter-driver) — external WebDriver automation and the trade-offs of Flutter-specific community drivers.
