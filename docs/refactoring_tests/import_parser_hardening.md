# Import And Parser Hardening

## Status

- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-23
- Parent plan: `docs/refactoring_tests/testing_plan.md`, Package 2

## Scope

- Add focused tests for high-risk import pipeline gaps.
- Add parser negative-path regression tests.
- Preserve production behavior; this package is test-only.

## Non-goals

- Do not change parser heuristics or import behavior.
- Do not add new receipt fixture files.
- Do not add real receipt data, NIP values from real users, file paths, URIs, or raw payloads.
- Do not change CI coverage threshold.

## Current State Check

Files inspected:

- `lib/application/import/import_receipt_use_case.dart`
- `lib/features/import/import_service.dart`
- `lib/data/repositories/receipt_repository.dart`
- `lib/domain/parsing/receipt_parser.dart`
- `test/import_pipeline_test.dart`
- `test/receipt_parser_new_format_test.dart`

Existing behavior confirmed:

- `ImportService` delegates to `ImportReceiptUseCase`.
- Exact duplicate detection uses `fileHash`.
- Heuristic duplicate detection uses merchant/date/total.
- Empty extracted PDF pages fall back to JSON/text file parsing.
- Successful imports persist receipt/items and rebuild aggregates.
- Error results map to user-safe messages.

## Changes

Import pipeline tests added:

- Empty extracted PDF pages can still import a JSON receipt through fallback.
- `importMany` keeps one successful import and one heuristic duplicate isolated.
- A failed import does not persist data and can be retried successfully.
- Empty PDF plus invalid fallback returns a safe message and does not persist data.

Parser tests added:

- Unsupported text is rejected and does not become a false-positive receipt.
- Supported Biedronka-like text without purchase date is rejected with `Missing purchase date`.
- Supported Biedronka-like text without total is rejected with `Missing total amount`.
- Malformed JSON payload is rejected.

## Affected Files

- `test/import_pipeline_test.dart`
- `test/receipt_parser_new_format_test.dart`
- `docs/refactoring_tests/import_parser_hardening.md`
- `docs/refactoring_tests/testing_plan.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| New tests rely on current safe-message strings. | Assertions target messages that are already treated as user-facing import behavior. |
| Heuristic duplicate test becomes flaky if sample receipt parsing changes. | Uses the same deterministic sample text twice with different hashes and asserts only one persisted receipt. |
| Retry test could leave partial data after failure. | Explicitly asserts empty `receipts` and `line_items` tables after the first failure. |
| Formatter/tooling instability hides code issues. | Ran formatter directly through `dart.exe`; analyzer and tests passed afterward. |

## Tests And Checks

- [x] `dart format test/import_pipeline_test.dart test/receipt_parser_new_format_test.dart`
  - Files formatted successfully.
  - Dart returned a telemetry access error for `%APPDATA%`, unrelated to file formatting.
- [x] `flutter test test/import_pipeline_test.dart`
- [x] `flutter test test/receipt_parser_new_format_test.dart`
- [x] `flutter test`
- [x] `flutter analyze`
- [x] `dart run tool/test_with_coverage.dart --min-coverage=50`

## Coverage Evidence

- Coverage after Package 2: 51.54% line coverage, 1523/2955 lines.
- Coverage run seed: `3738629011`.
- Previous Package 1 current-workspace baseline: 50.63% line coverage, 1496/2955 lines.

## Definition Of Done

- [x] Import pipeline covers empty extraction fallback.
- [x] Import pipeline covers heuristic duplicate in batch flow.
- [x] Import pipeline covers retry after failed import.
- [x] Import pipeline verifies safe error messages and no persistence after controlled failures.
- [x] Parser covers unsupported text, missing date, missing total, and malformed JSON.
- [x] Analyzer and full fast test suite pass.
- [x] Coverage gate at `--min-coverage=50` passes.

## Completion Notes

- Completed on: 2026-06-23
- Decisions made:
  - Keep CI coverage threshold at 50%; 51.54% still leaves too little margin to raise the gate.
  - Do not add new fixture files until a new parser format requires a realistic regression sample.
- Follow-ups:
  - Package 3: database/migration hardening.
  - Package 4: UI state and localization coverage, especially `ImportView` rendering states.
