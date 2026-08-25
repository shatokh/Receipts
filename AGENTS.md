# AI Assistant Instructions for Receipts Project

## Instruction Source Of Truth
`AGENTS.md` is the primary instruction source for AI coding agents in this repository. If `.github/copilot-instructions.md`, project skills, or older docs disagree with this file, follow `AGENTS.md` and update the stale source when the task touches that area.

Keep project skills under `.codex/skills/` synchronized with these rules. In particular, l10n work must account for all supported locales: English, Russian, and Polish.

## Project Overview
Receipts is a Flutter MVP for tracking and analyzing PDF or JSON receipt exports with on-device processing. The app is offline-first: receipt parsing, storage, analytics, and UI state should work without network access. Sentry is optional and must not receive receipt contents or personally identifiable information.

Key stack:
- State management: `flutter_riverpod`
- Navigation: `go_router`
- Database: `sqflite` with `sqflite_common_ffi` for tests
- Charts: `fl_chart`
- File import: `file_picker`
- Android PDF extraction: MethodChannel-backed `PdfTextExtractor`
- Error tracking: optional `sentry_flutter`

## Project Structure
```
lib/
├── app/                 # Router, app-level providers, scaffold
├── core/                # Cross-cutting app concerns
├── data/                # SQLite helper, update bus, repositories
├── di/                  # Test/runtime override helpers
├── domain/              # Models, parsing, category definitions
├── features/            # Feature UI and controllers
├── l10n/                # ARB files and generated localizations
└── platform/            # Platform-specific service implementations
```

## Current Architecture Ownership
- `lib/app/providers.dart` is a backward-compatible barrel. Add new providers to focused files under `lib/app/providers/`, not to the barrel.
- New app-flow orchestration belongs in `lib/application/` when it is not purely UI state. Keep widgets/controllers thin and provider-driven.
- `ImportService` is a compatibility wrapper; import orchestration belongs in `ImportReceiptUseCase`.
- Repositories still own receipt write persistence, aggregate updates, and `DatabaseUpdateBus` notifications. Do not add a second aggregate-update path in use cases unless a dedicated sub-plan explicitly changes ownership.
- Until repository ports are introduced, `application/` may depend on concrete repositories only as a documented transition compromise.

## Layer Boundaries
- `domain/` must stay pure Dart: no Flutter widgets, Riverpod, sqflite, platform channels, or generated localization dependencies.
- `data/` may depend on `domain/` and `core/`, but not on feature widgets/controllers.
- `application/` may coordinate repositories and services, but must not depend on concrete UI.
- Flutter-only UI types such as `RangeValues` must remain at widget/provider adapter boundaries, not in domain/application contracts.
- Feature view models should stay pure presentation mapping where possible. Pass formatted primitive values instead of making them depend on BuildContext or generated l10n classes.

## Core Invariants
- Keep receipt processing local. Do not add network calls to core import, parsing, storage, or analytics flows unless the user explicitly asks for a sync/backup feature.
- Do not log raw receipt text, line items, totals, NIP values, file paths/URIs, or PDF payloads. This applies to `developer.log`, Sentry, test output, and debug UI.
- User-facing text belongs in `lib/l10n/app_en.arb`, `lib/l10n/app_ru.arb`, and `lib/l10n/app_pl.arb`; do not hardcode visible strings in widgets.
- Platform integrations must stay behind interfaces/providers so tests can override them.
- Money and date logic must be deterministic. Normalize Polish decimal commas, avoid direct `double` equality in tests, and filter months with `[monthStart, nextMonthStart)` ranges.

## Privacy And Logging Guardrails
- Route new import/logging/telemetry details through `PrivacySanitizer` or an equivalent allowlist before writing them anywhere.
- Safe logs may include technical status fields such as stage/status/page count. They must not include `sourceUri`, file paths, SAF/content URIs, raw parser payloads, NIP values, receipt text, line items, totals, merchant addresses, or PDF text.
- User-facing import errors must be generic and safe. Do not surface raw exception messages unless they are explicitly allowlisted.
- When changing import error handling, telemetry, Sentry configuration, or developer logs, add or update tests that prove sensitive values are redacted.

## Epic Planning Rule
When working on a multi-phase epic such as `docs/framework_refactoring_plan.md`, do not implement a phase directly from the master plan alone.

For every phase or major section:
- Create or update a dedicated sub-plan under `docs/refactoring_subplans/`.
- The sub-plan must include scope, non-goals, implementation steps, affected files, risks, tests/checks, and phase-specific Definition of Done.
- Keep the sub-plan small enough to map to one PR or one clearly reviewable work package. Split it further if it grows too broad.
- Before starting implementation, verify the sub-plan still matches the current repository state.
- During implementation, update the sub-plan when scope, risks, or acceptance criteria change.
- After finishing the sub-plan, update both the sub-plan and the master plan tracker in `docs/framework_refactoring_plan.md`.
- Mark the master plan phase status accurately: not started, planned, in progress, blocked, complete, or superseded.
- Record completion evidence: tests run, docs updated, important decisions made, and remaining follow-up work.

The master plan is a coordination artifact, not a stale checklist. If code or project direction diverges from it, update the tracker before continuing the next phase.

## Navigation
- Routes are defined in `lib/app/router.dart`.
- The main app uses a `ShellRoute` with `MainScaffold` for tabbed sections.
- Current route structure:
  - `/onboarding`
  - `/dashboard`
  - `/month`
  - `/receipts`
  - `/receipt/:id`
  - `/settings`
  - `/settings/language`
  - `/import`

## Riverpod Patterns
- Add app-wide dependencies in `lib/app/providers.dart`.
- Keep platform services overrideable: `pdfTextExtractorProvider`, `fileImportServiceProvider`, `settingsRepositoryProvider`.
- Prefer `FutureProvider`, `StreamProvider`, `AsyncNotifier`, or small `StateNotifier` classes over stateful widget business logic.
- When repositories expose update streams, invalidate or re-emit through the existing `DatabaseUpdateBus` pattern.
- UI should render `AsyncValue` loading/error/data states explicitly.

## Import Pipeline
The import flow is:
1. Pick/copy a file with `FileImportService`.
2. Compute `fileHash`.
3. Reject exact duplicates by hash.
4. Extract PDF pages or fall back to JSON/text payload parsing.
5. Parse with `ReceiptParser`.
6. Reject heuristic duplicates by merchant/date/total.
7. Insert receipt and line items in one transaction.
8. Update monthly/category aggregates.
9. Notify listeners.

When editing this pipeline:
- Cover both PDF text extraction and JSON fallback paths when relevant.
- Preserve idempotency and duplicate behavior.
- Return user-safe `ImportResult.message` values. Never expose raw parser payloads.
- Update tests in `test/import_pipeline_test.dart` or parser-focused tests for behavior changes.
- Check aggregate behavior after success and after duplicate/error paths. Duplicate or failed imports must not mutate receipt tables or aggregate tables.

## Database Rules
- SQLite compatibility export lives in `lib/data/database.dart`; implementation files live under `lib/data/database/`; repositories live in `lib/data/repositories/`.
- Multi-table writes must use `db.transaction`.
- Schema changes require:
  - incrementing `DatabaseHelper.dbVersion`
  - updating fresh schema creation
  - adding an `_upgradeDB` migration path
  - testing migration-sensitive repository behavior
- Keep aggregate tables (`monthly_totals`, `category_month_totals`) consistent after receipt writes.
- Use query arguments (`whereArgs`, raw query parameters), not interpolated SQL values.

## Localization
- Edit ARB files first: `lib/l10n/app_en.arb`, `lib/l10n/app_ru.arb`, and `lib/l10n/app_pl.arb`.
- Include placeholder metadata for interpolated strings and plurals.
- Regenerate localizations with `flutter gen-l10n` after ARB changes.
- Commit ARB and generated `app_localizations*.dart` files together.
- Do not manually edit generated `app_localizations*.dart` unless Flutter generation is unavailable and that tradeoff is documented in the sub-plan or PR notes.
- Format dates/currency with `intl` and the active locale where UI-facing.

## Testing
- Default command: `flutter test`.
- Coverage gate: `dart run tool/test_with_coverage.dart`.
- Import/parser changes should include focused unit tests and, when the UI flow changes, integration coverage.
- Use `TestAppHarness` or `createTestContainer` from `test/helpers/test_environment.dart` for isolated Riverpod and SQLite state.
- Use fakes/overrides for platform services; unit tests must not call Android MethodChannels.
- For integration tests, see `README_TESTING.md` and the scripts in `tool/`.

### Test Command Selection
- For focused changes, run the smallest relevant test target first.
- For broad architecture, provider, import, database, or UI shell changes, run `flutter analyze` and `flutter test` before finishing.
- The current CI coverage gate is `dart run tool/test_with_coverage.dart --min-coverage=50` in `.github/workflows/sonar-scan.yml`. Do not raise it without measuring a fresh baseline and recording the decision in docs.
- Android integration tests are manual-only and must not be added to the coverage gate.

## Common Tasks

### Adding a Feature
1. Create `lib/features/<feature>/`.
2. Add UI and controller/state files following nearby feature patterns.
3. Register routes in `lib/app/router.dart` when needed.
4. Add providers in `lib/app/providers.dart` only for shared dependencies.
5. Add localized strings and tests.

### Changing Receipt Parsing
1. Add or update a realistic fixture/sample.
2. Add parser expectations for success and failure paths when behavior changes.
3. Assert date, total, VAT, item count, representative items, merchant, and categories.
4. Keep normalization rules conservative; do not break existing Biedronka/Polish receipt samples.
5. Use `closeTo` for monetary assertions.
6. Verify parser/import failure messages stay safe and do not reveal the source payload.

### Changing Platform Code
- Keep the Dart interface in `lib/platform/pdf_text_extractor/pdf_text_extractor.dart` synchronized with Android implementation.
- Update fakes in `test/test_infra/fakes/` when the interface changes.
- Keep Android-specific code out of domain and repository layers.

## Useful Project Skills
Project skill files live under `.codex/skills/`:
- `receipts-import-pipeline` for import, parsing, duplicate detection, and aggregate changes.
- `receipts-database-migration` for SQLite schema and migration work.
- `receipts-l10n` for localized UI text changes.
- `receipts-test-harness` for unit, widget, repository, and import tests.
