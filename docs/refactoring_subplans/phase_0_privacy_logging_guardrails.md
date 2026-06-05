# Phase 0: Privacy Logging Guardrails

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 0. Baseline, guardrails и минимальное покрытие`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-02

## Scope

- Establish a baseline with analyze/test/coverage commands where practical.
- Harden import error logging and import telemetry so they do not record raw file URIs, receipt content, parser payloads, NIP values, line items, totals, or unsanitized error details.
- Keep import behavior user-safe: error results should not expose raw exception strings.
- Add focused P0 tests around import error messages and logging sanitization.
- Update the master plan tracker and this sub-plan when done.

## Non-goals

- Do not restructure providers, repositories, or the import use-case layer in this phase.
- Do not change parser behavior except where needed to keep failure messages safe.
- Do not introduce Sentry integration changes unless a current logging path requires it.
- Do not implement clear data, delete receipt, recategorization, bulk import UX, or PDF open features.
- Do not chase the long-term 70-75% coverage target in this phase.

## Current State Check

- Files inspected:
  - `lib/features/import/import_service.dart`
  - `lib/core/logging/error_log_service.dart`
  - `lib/data/repositories/analytics_repository.dart`
  - `test/import_pipeline_test.dart`
  - `test/helpers/test_environment.dart`
- Existing behavior confirmed:
  - `ImportService.importOne` catches errors and returns `ImportResult(status: error)`.
  - PDF extraction can fall back to JSON/text parsing.
  - `ErrorLogService(enabled: false)` is already a no-op.
  - Import telemetry currently writes through `developer.log`.
- Known gaps:
  - `ErrorLogService.logImportFailure` accepts and writes raw `safUri`.
  - Local import error logs can include raw `error.toString()` and full `stackTrace`.
  - Import telemetry can log raw `sourceUri`.
  - Unexpected import errors can return `error.toString()` in a user-facing `ImportResult.message`.
  - `ErrorLogService` resolves the real app documents directory, so focused tests need an injectable file resolver or a narrower abstraction.

## Implementation Steps

1. Add a small privacy/logging helper or sanitize methods that allow only safe technical fields.
2. Update `ErrorLogService` to write allowlisted import failure payloads and support an injectable log file resolver for tests.
3. Update `ImportService` error mapping so unexpected errors return a generic user-safe message.
4. Update import telemetry to avoid raw `sourceUri`; record only safe technical identifiers such as a redacted source marker and stage.
5. Add focused tests for safe import errors and safe local logging.
6. Run focused tests, then broader checks as time/environment permits.
7. Update completion notes and the master plan tracker.

## Affected Files

- `lib/core/logging/error_log_service.dart`
- `lib/data/repositories/analytics_repository.dart`
- `lib/features/import/import_service.dart`
- `test/import_pipeline_test.dart`
- `test/core/error_log_service_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_0_privacy_logging_guardrails.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Removing too much error detail makes import failures hard to debug. | Keep safe stage/error-type fields and sanitized details allowlist. |
| Logging abstraction adds unnecessary framework weight. | Use the smallest injectable file resolver needed for tests. |
| User-facing messages change and break UI expectations. | Assert status/message only for behavior that must be stable. |
| Telemetry still leaks through nested details. | Sanitize details recursively by allowlist and primitive values only. |

## Tests And Checks

- [x] `flutter analyze`
- [x] `flutter test test/import_pipeline_test.dart`
- [x] `flutter test test/core/error_log_service_test.dart`
- [x] `flutter test`
- [x] `dart run tool/test_with_coverage.dart --min-coverage=0`

## Definition Of Done

- [x] Import error logging does not write raw `safUri`, receipt text, file paths, parser payloads, NIP values, line items, totals, or raw stack traces.
- [x] Import telemetry does not write raw `sourceUri`.
- [x] Unexpected import errors return a generic user-safe message.
- [x] Focused tests cover safe local logging and safe import error messaging.
- [x] Behavior for successful imports, hash duplicates, heuristic duplicates, and JSON fallback remains unchanged.
- [x] Relevant tests/checks pass or known failures are documented.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-02
- Tests run:
  - `flutter test test/core/error_log_service_test.dart`
  - `flutter test test/import_pipeline_test.dart`
  - `flutter analyze`
  - `flutter test`
  - `dart run tool/test_with_coverage.dart --min-coverage=0`
- Coverage baseline: 35.35% line coverage (503/1423 lines).
- Decisions made:
  - Use `PrivacySanitizer` for allowlisted import log/telemetry details.
  - Keep `safUri` in `ImportResult.sourceUri` for UI retry/display behavior, but redact it from logs and telemetry.
  - Store `errorType` and `stackTracePresent` instead of raw exception text or raw stack traces in local import logs.
  - Return a generic message for unexpected import exceptions.
  - Redact Android logcat messages that previously included SAF URIs, file paths, or embedded attachment names.
- Follow-ups:
  - Phase 0b still needs repository, aggregate, database watch, and month helper P0 tests before database/use-case refactor.
  - Sentry payload/breadcrumb review remains part of the later privacy/logging framework completion if Sentry usage grows beyond current initialization.
