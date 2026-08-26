# Phase 12: Clear Receipt Data

## Master Plan Link

- Master work package: `docs/framework_refactoring_plan.md` section 8, feature work
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-08-26

## Scope

- Replace the Settings clear-data placeholder with a confirmed, destructive operation.
- In one SQLite transaction, remove receipts, their line items, and all monthly/category aggregate rows.
- Preserve app configuration, category taxonomy, and bundled merchant metadata so the app remains usable after cleanup.
- Notify data listeners only after the transaction commits and show localized, non-sensitive success/failure feedback.
- Add repository and Settings widget coverage.

## Non-goals

- Do not reset language, crash-reporting, developer logging, onboarding, or other SharedPreferences values.
- Do not delete bundled categories or merchant metadata.
- Do not implement undo, export, backup, or account/sync behavior.
- Do not change the database schema or migration version.

## Current State Check

Files inspected:

- `lib/data/repositories/receipt_repository.dart`
- `lib/data/database/database_schema.dart`
- `lib/features/settings/settings_view.dart`
- `lib/features/settings/widgets/debug_settings_section.dart`
- `test/data/receipt_repository_test.dart`
- `test/features/settings/settings_view_test.dart`

Existing behavior confirmed:

- Receipt data lives in `receipts`, `line_items`, `monthly_totals`, and `category_month_totals`.
- Settings presents a confirmation dialog but ends with a “not implemented” snackbar.
- `ReceiptRepository` owns aggregate persistence and `DatabaseUpdateBus` notifications.
- Categories and the two bundled merchant records are seed metadata, not receipt history.

Known gaps:

- No repository operation clears receipt data atomically.
- No UI in-progress protection, success feedback, or safe failure feedback exists.
- Existing wording promises an app reset although the intended safe scope is receipt data only.

## Implementation Steps

1. Add an atomic `ReceiptRepository` operation for receipt data cleanup and post-commit update notification.
2. Wire the Settings dialog through an injectable async callback with in-progress protection.
3. Update EN/RU/PL wording to state the precise cleared scope; add success and generic failure messages and regenerate localizations.
4. Add repository and widget tests for confirmation, cleanup, listener update, and safe failure UI.
5. Run focused checks, analyzer, and the full fast suite.
6. Record completion evidence here and in the master tracker.

## Affected Files

- `lib/data/repositories/receipt_repository.dart`
- `lib/features/settings/settings_view.dart`
- `lib/features/settings/widgets/debug_settings_section.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ru.arb`
- `lib/l10n/app_pl.arb`
- generated `lib/l10n/app_localizations*.dart`
- `test/data/receipt_repository_test.dart`
- `test/features/settings/settings_view_test.dart` or a focused Debug Settings widget test
- `docs/framework_refactoring_plan.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| User triggers an irreversible cleanup accidentally. | Require explicit confirmation and render the action as destructive. |
| A failure leaves partially removed receipt state. | Delete all receipt tables inside one SQLite transaction. |
| Repeated taps trigger concurrent cleanup. | Disable the action while its Future is pending. |
| Settings are unexpectedly reset. | Keep SharedPreferences and seeded metadata outside the cleanup scope and describe that scope in the dialog. |
| UI exposes private data or raw errors. | Use only localized generic failure feedback and no logging. |

## Tests And Checks

- [x] `flutter test test/data/receipt_repository_test.dart`
- [x] focused Settings widget test
- [x] `flutter test test/l10n/category_localizations_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] The Settings action requires confirmation before clearing receipt data.
- [x] Receipts, line items, and aggregate tables are empty together after success.
- [x] Seed metadata and app preferences remain outside the cleanup scope.
- [x] Data listeners update only after a successful transaction.
- [x] Success/failure UI is localized and does not expose raw errors.
- [x] EN/RU/PL ARB and generated files are synchronized.
- [x] Relevant tests and checks pass.
- [x] Master tracker and completion notes are updated; follow-up work is recorded.

## Completion Notes

- Completed on: 2026-08-26
- Tests run:
  - `flutter test test/data/receipt_repository_test.dart`
  - `flutter test test/features/settings/settings_view_test.dart`
  - `flutter test test/l10n/category_localizations_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - “Clear all data” clears receipt history and aggregates, not language, privacy/debug preferences, categories, or bundled merchant metadata.
  - Receipt tables are cleared in one SQLite transaction; listeners are notified only after it commits.
  - The dialog wording states this precise scope and the UI exposes only localized generic errors.
- Follow-ups:
  - Open-PDF and recategorization remain independent Receipt Details feature packages.
  - Backups/export and undo are separate product decisions; do not add them implicitly to destructive flows.
