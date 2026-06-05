# Phase 4: Privacy Logging Completion

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 4. Укрепить privacy/logging framework`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-02

## Scope

- Audit current logging paths after Phase 0 guardrails.
- Confirm local import error logs, import telemetry, and Android logcat messages do not include raw receipt/file/user data.
- Update privacy documentation if current behavior includes local developer logging.
- Re-run relevant focused checks.

## Non-goals

- Do not introduce a larger logging framework unless the audit finds a gap.
- Do not change Sentry initialization or add breadcrumbs.
- Do not change import behavior.

## Current State Check

- Files inspected:
  - `lib/core/privacy/sanitizer.dart`
  - `lib/core/logging/error_log_service.dart`
  - `lib/data/repositories/analytics_repository.dart`
  - `lib/application/import/import_receipt_use_case.dart`
  - `android/app/src/main/kotlin/app/receipts/MainActivity.kt`
  - `docs/privacy.md`
- Existing behavior confirmed:
  - Local import error logs use redacted source markers, error type, stack trace presence, and allowlisted technical details.
  - Import telemetry redacts `sourceUri`.
  - Android logcat import/PDF extraction messages no longer include raw SAF URI, paths, or attachment names.
  - Sentry is initialized only when enabled and no app breadcrumbs are currently added in Dart.
- Known gaps:
  - Privacy policy does not mention optional local developer import error logs.

## Implementation Steps

1. Run a logging-path search for raw URI/path/error/stack trace patterns.
2. Update `docs/privacy.md` to mention optional local redacted developer import logs.
3. Run focused logging/import tests.
4. Update completion notes and master plan tracker.

## Affected Files

- `docs/privacy.md`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_4_privacy_logging_completion.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Documentation over-promises privacy behavior. | Keep wording specific to current local redacted developer logs. |
| Hidden logging path remains. | Use repository-wide targeted searches for logging and raw source patterns. |

## Tests And Checks

- [x] logging-path search
- [x] `flutter test test/core/error_log_service_test.dart test/import_pipeline_test.dart`

## Definition Of Done

- [x] Logging audit completed.
- [x] Privacy documentation matches current local developer logging behavior.
- [x] Focused logging/import tests pass.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-02
- Tests run:
  - `rg -n "FileOutputStream|embedded-dumps|absolutePath|stackTrace\\.toString|error\\.toString|Unexpected error while importing:" lib android/app/src/main/kotlin/app/receipts/MainActivity.kt test`
  - `rg -n "Log\\." android/app/src/main/kotlin/app/receipts/MainActivity.kt`
  - `flutter test test/core/error_log_service_test.dart test/import_pipeline_test.dart`
- Decisions made:
  - Document optional local developer import logs in `docs/privacy.md`.
  - Disable Android embedded payload dumping because payload bytes may contain raw receipt data.
  - Keep Android logcat messages technical and redacted.
  - No Sentry breadcrumb changes are needed because current Dart code only initializes Sentry when enabled and does not add receipt breadcrumbs.
- Follow-ups:
  - If Sentry breadcrumbs or custom events are added later, add explicit safe-event tests or review checklist entries.
