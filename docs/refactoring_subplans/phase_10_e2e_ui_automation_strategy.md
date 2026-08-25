# Phase 10: E2E UI Automation Strategy

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 10. CI и quality gates`
- Status: planned
- Owner/agent: Codex
- Last updated: 2026-06-23

## Scope

- Decide how Receipts should distribute UI and end-to-end checks across unit, repository/use-case, widget, Flutter `integration_test`, and possible Patrol-based tests.
- Evaluate whether Patrol should be introduced now, piloted later, or avoided.
- Define the main user flows that deserve automation.
- Align the decision with the existing master plan, current `integration_test/` harness, manual Android workflow, and offline/privacy constraints.

## Non-goals

- Do not add Patrol dependencies in this planning package.
- Do not rewrite the existing `integration_test/app_flow_test.dart`.
- Do not make emulator/device tests block every PR.
- Do not add network-dependent test flows.
- Do not use real receipt data, real NIP values, user file paths, or personal documents in E2E fixtures.
- Do not replace unit/widget/repository coverage with E2E tests.

## Current State Check

Files inspected:

- `docs/framework_refactoring_plan.md`
- `docs/refactoring_tests/testing_plan.md`
- `README_TESTING.md`
- `.github/workflows/integration_test.yml`
- `integration_test/app_flow_test.dart`
- `integration_test/test_keys.dart`
- `lib/di/test_overrides.dart`
- `test/test_infra/fakes/fake_file_import_service.dart`
- `pubspec.yaml`
- `android/app/build.gradle`
- `android/app/src/main/AndroidManifest.xml`

Existing behavior confirmed:

- The app already has a manual-only Android integration workflow.
- `integration_test/app_flow_test.dart` boots the real app shell with provider overrides.
- Integration tests use fake file import and fake PDF text extraction, so they are deterministic and offline.
- The current E2E smoke flow covers onboarding, tab navigation, import success, receipt list, stats chart, lifecycle pause/resume, and broken PDF extraction error.
- Android package/application id is `app.receipts`.
- Current `pubspec.yaml` uses Flutter `integration_test` and does not include Patrol.

Official docs checked:

- Flutter integration tests are the SDK-supported path for app-level tests in `integration_test/`; they can tap widgets, verify text, and run on Android/iOS/desktop/web depending on target setup. Source: `https://docs.flutter.dev/testing/integration-tests`.
- Patrol positions itself as a Flutter E2E UI testing framework that extends beyond `integration_test` with native interactions such as permission dialogs, notifications, WebViews, device settings, and native views. Source: `https://patrol.leancode.co/`.
- Patrol CLI requires `patrol_cli`, a `patrol` dev dependency, native setup, and `patrol test`; Patrol docs state that plain `flutter test` does not run Patrol UI tests. Source: `https://patrol.leancode.co/documentation`.
- Patrol supports selecting test targets/tags, native-format results, Android/iOS native runners, experimental/full isolation options, and web support through Playwright. Source: `https://patrol.leancode.co/cli-commands/test`.

## Strategy Decision

Adopt a layered hybrid strategy:

1. Keep `flutter test` as the fast PR gate for unit, repository/use-case, parser, privacy, and widget tests.
2. Keep Flutter `integration_test` as the default E2E app-flow harness for deterministic, provider-overridden, offline flows.
3. Do not migrate existing integration tests to Patrol now.
4. Add a separate Patrol spike only if we need to automate real native surfaces that `integration_test` cannot cover well:
   - Android permission dialogs.
   - Real Storage Access Framework/file picker interactions.
   - Real PDF/OCR/native extraction path.
   - App background/foreground or system settings behavior that cannot be simulated reliably.
5. Keep all emulator/device E2E checks manual-only or scheduled until runtime and flakiness are proven acceptable.

Rationale:

- Receipts' core risk is not native UI complexity; it is local parsing, duplicate detection, SQLite consistency, privacy, and state rendering. Those are cheaper and more reliable below the E2E layer.
- The current integration harness can inject fakes through Riverpod, which keeps E2E flows deterministic and avoids brittle Android file picker setup.
- Patrol is valuable for native automation, but it adds setup, CLI, native build, and CI surface area. That cost is justified only for native flows that cannot be covered by the existing harness.

## Options Considered

### Option A. Stay On Flutter `integration_test`

Use existing `integration_test/` and improve flow coverage.

Pros:

- Already installed and working.
- Reuses `buildTestApp`, provider overrides, fake import service, fake PDF extractor, and controlled SQLite database.
- Easy to keep offline and privacy-safe.
- Lower setup and CI maintenance.

Cons:

- Limited native automation.
- Real Android permission/file picker behavior remains mostly untested.
- One broad flow can be hard to diagnose when it fails.

Recommended use:

- Default choice for app-shell E2E smoke and deterministic user journeys.

### Option B. Patrol Pilot For Native Flows

Add Patrol as a separate pilot suite while keeping existing `integration_test`.

Pros:

- Covers native interactions that `integration_test` struggles with.
- Patrol has native automation APIs and dedicated CLI/test runner.
- Better candidate for real Android SAF/file picker and permission dialogs.
- Can run as manual-only/scheduled and stay outside fast PR gate.

Cons:

- Requires `patrol_cli`, `patrol` dev dependency, `pubspec.yaml` `patrol` section, Android native setup, and CI changes.
- Plain `flutter test` will not run Patrol tests.
- More moving parts: generated `test_bundle.dart`, native build/test apps, possible Gradle/SDK friction.
- Potential overlap with existing integration tests if scope is not strict.

Recommended use:

- Run a small Android-only spike after current widget/integration coverage is stabilized.
- Keep the first Patrol test narrow: real native import surface or permission/file picker smoke, not full app regression.

### Option C. Full Patrol Migration

Move all integration tests to Patrol.

Pros:

- One E2E framework for Flutter + native surfaces.
- Patrol features such as tags, native test results, isolation options, and device-farm compatibility become standard.

Cons:

- Too much churn for current needs.
- Would replace a working deterministic harness before proving native automation is required.
- Increases CI and local setup burden.

Decision:

- Not recommended now.

### Option D. External Black-Box Tools

Examples: Maestro/Appium/device-farm scripted flows.

Pros:

- Tests app like an installed black-box product.
- Useful for release APK smoke tests or non-Flutter teams.

Cons:

- Harder to reuse Dart fakes, Riverpod overrides, and test database setup.
- More brittle selectors unless accessibility ids/keys are carefully exposed.
- Adds another language/tooling layer.

Decision:

- Defer. Reconsider only for release candidate testing outside the Flutter repo workflow.

## Test-Level Distribution

| Check / Flow | Unit / Domain | Repository / Use Case | Widget | Flutter `integration_test` | Patrol Candidate |
| --- | --- | --- | --- | --- | --- |
| Parser formats, VAT, discounts, dates | Primary | No | No | No | No |
| Duplicate detection and safe import messages | Parser support only | Primary | Message rendering only | One smoke path | No |
| SQLite aggregate consistency | No | Primary | No | Persistence smoke only | No |
| Privacy/logging sanitization | Primary for sanitizer | Primary for import/logging | No raw UI errors | Smoke only | No |
| Dashboard/month/receipts loading/error/empty/data | View-model mapping | Provider fakes | Primary | Navigation smoke | No |
| Import screen success/duplicate/error/partial rendering | No | Use-case results | Primary | Main import flow smoke | No |
| Onboarding and shell tab navigation | No | No | Route/widget smoke | Primary smoke | No |
| Receipt appears after import and details opens | No | Repository/use-case | Widget route smoke | Primary smoke | No |
| Language/settings flow | Locale/controller tests | Settings repo tests | Primary | Optional smoke | No |
| App lifecycle pause/resume | No | No | No | Existing smoke | Patrol only if native state matters |
| Real Android file picker / SAF | No | No | No | Hard to make deterministic | Primary candidate |
| Permission dialogs / system settings | No | No | No | Hard to make deterministic | Primary candidate |
| Real PDF/OCR native extraction | Parser expected output only | Import fallback behavior | No | Possible but brittle | Candidate manual smoke |

## Main User Flows To Automate

### Fast Widget-Level UI Flows

These should run under `flutter test` and block PRs:

1. ImportView rendering matrix:
   - initial/empty
   - loading
   - success
   - duplicate
   - error
   - partial batch result
2. Dashboard:
   - loading
   - empty
   - populated KPI/chart/category state
   - provider error state
3. Month:
   - empty month
   - populated month
   - month picker change
   - provider error state
4. Receipts:
   - empty list
   - populated list
   - query/month/amount filters
5. Receipt details:
   - loading
   - populated details
   - missing receipt/error state
6. Settings/language:
   - sections render
   - language page opens
   - locale controller updates visible language state

### Flutter `integration_test` E2E Flows

These should remain emulator/device tests and stay manual-only until proven cheap:

1. Happy import journey:
   - onboarding
   - import sample PDF via fake service
   - success status
   - receipt appears in list
   - details opens
   - dashboard/month stats update
2. Duplicate import journey:
   - import sample
   - import same logical receipt with different hash
   - duplicate message/status appears
   - database still has one receipt
3. JSON fallback journey:
   - PDF extraction fails
   - JSON fallback imports successfully
   - receipt appears and stats update
4. Error journey:
   - broken/empty PDF
   - safe error status appears
   - no raw URI/path/NIP in visible message
5. Persistence journey:
   - import receipt
   - rebuild/restart app shell
   - receipt and stats are still present
6. Lifecycle smoke:
   - pause/resume while dashboard or import result is visible
   - app returns to stable state

### Patrol Spike Flows

Only after a separate setup PR:

1. Android native import surface smoke:
   - start app
   - tap import
   - interact with native picker or permission path if available in test environment
   - assert app returns to import result state
2. Android permission/system dialog smoke:
   - exercise permission grant/deny path if feature behavior depends on runtime permissions
3. Native PDF/OCR smoke:
   - run one real asset/file through Android extraction path
   - assert only high-level success/error state, not full parser details

## Proposed Implementation Steps

1. Update this sub-plan and master tracker with the chosen layered strategy.
2. Add/extend widget tests first:
   - `test/features/import/import_view_test.dart`
   - `test/features/dashboard/dashboard_view_test.dart`
   - `test/features/month/month_view_test.dart`
   - `test/features/receipts/receipts_view_test.dart`
   - `test/features/receipt_details/receipt_details_view_test.dart`
   - `test/features/settings/settings_view_test.dart`
3. Split `integration_test/app_flow_test.dart` into focused flows or add focused tests beside it:
   - `integration_test/import_happy_flow_test.dart`
   - `integration_test/import_duplicate_flow_test.dart`
   - `integration_test/import_json_fallback_flow_test.dart`
   - `integration_test/persistence_flow_test.dart`
4. Keep `.github/workflows/integration_test.yml` manual-only.
5. Add test keys only where stable UI automation needs them; avoid asserting brittle English text except when text itself is the behavior.
6. After widget/integration gaps are closed, create a Patrol spike sub-plan if native coverage is still needed.
7. Patrol spike setup, if approved:
   - add `patrol` dev dependency;
   - install/use `patrol_cli`;
   - add `patrol` section to `pubspec.yaml` with `app_name: Receipts`, Android package `app.receipts`, and either `test_directory: patrol_test` or a deliberately separate directory;
   - add generated `test_bundle.dart` path to `.gitignore`;
   - add a manual-only workflow or script;
   - add exactly one Android smoke test.

## Affected Files

Planning files:

- `docs/refactoring_subplans/phase_10_e2e_ui_automation_strategy.md`
- `docs/framework_refactoring_plan.md`

Likely implementation files for follow-up packages:

- `integration_test/app_flow_test.dart`
- `integration_test/test_keys.dart`
- `README_TESTING.md`
- `.github/workflows/integration_test.yml`
- `test/features/*/*_test.dart`
- `pubspec.yaml` only if Patrol spike is approved
- `.gitignore` only if Patrol spike is approved
- Android Gradle files only if Patrol native setup requires it

## Risks

| Risk | Mitigation |
| --- | --- |
| Too many E2E tests become flaky and slow. | Keep PR gate focused on unit/widget tests; keep emulator/device tests manual-only until metrics justify promotion. |
| Patrol adds setup cost without clear benefit. | Run a one-test Android spike only for native surfaces; do not migrate existing deterministic flows. |
| UI tests become brittle through visible English text assertions. | Prefer stable keys for navigation/layout and localized strings only when text behavior matters. |
| E2E tests duplicate repository/use-case coverage. | Use E2E for wiring and journeys; keep rules, parsing, aggregates, and privacy assertions below UI level. |
| Real file picker/OCR tests need real documents. | Use synthetic assets only and assert high-level states; never commit personal receipts or raw user documents. |
| Integration workflow runtime grows beyond budget. | Split flows, measure runtime, and keep manual/scheduled workflow separate from fast PR checks. |

## Tests And Checks

Planning-only package:

- [ ] No code tests required.
- [ ] Review links and decisions against current project state.
- [ ] Master plan tracker updated.

Future implementation packages:

- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] focused widget tests
- [ ] `flutter test integration_test -d emulator-5554` or `.\tool\it_android.ps1` for integration changes
- [ ] `patrol doctor` and `patrol test --target ...` only if Patrol spike is approved

## Definition Of Done

- [ ] Testing levels are explicitly mapped to user flows and risks.
- [ ] Patrol decision is documented as "pilot only when native automation is needed", not default migration.
- [ ] Current `integration_test` ownership remains clear.
- [ ] Slow E2E checks remain outside fast PR gate.
- [ ] Master plan tracker includes this work package.
- [ ] Follow-up implementation packages are listed.

## Completion Notes

- Completed on:
- Tests run:
- Decisions made:
- Follow-ups:
  - Package 4 from `docs/refactoring_tests/testing_plan.md`: UI state and localization widget coverage.
  - Focused `integration_test` flow split/expansion.
  - Optional Patrol Android spike after widget/integration gaps are closed.
