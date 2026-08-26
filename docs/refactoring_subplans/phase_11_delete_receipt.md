# Phase 11: Delete Receipt

## Master Plan Link

- Master work package: `docs/framework_refactoring_plan.md` section 8, feature work
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-08-26

## Scope

- Add a destructive, confirmed action to delete the receipt displayed on the Receipt Details screen.
- Delete the receipt and its line items, recompute affected month aggregates in the same SQLite transaction, and notify data listeners only after a successful commit.
- Return to the previous screen after success and show only localized, non-sensitive UI feedback.
- Cover the repository behavior and the widget confirmation/success flow.

## Non-goals

- No bulk deletion or Settings “clear all data” behavior.
- No undo, source-PDF deletion, recategorization, or open-PDF work.
- No schema change or migration.
- Do not display raw database exceptions or receipt data in UI/logs.

## Current State Check

Files inspected:

- `lib/data/repositories/receipt_repository.dart`
- `lib/data/aggregates_updater.dart`
- `lib/features/receipt_details/receipt_details_view.dart`
- `lib/features/receipt_details/widgets/action_buttons.dart`
- `lib/features/receipt_details/widgets/receipt_details_content.dart`
- `test/data/receipt_repository_test.dart`
- `test/features/receipt_details/receipt_details_view_test.dart`

Existing behavior confirmed:

- `ReceiptRepository.deleteReceipt` already removes line items and the receipt and updates aggregates afterwards.
- Receipt Details exposes only placeholder Open PDF and Re-categorize actions; there is no delete UI.
- The existing repository test covers deleting the final receipt in a month, but does not prove aggregate recomputation is committed atomically with deletion.

Known gaps:

- Aggregate recomputation occurs after the deletion transaction and can leave aggregates stale if it fails.
- There is no user confirmation, in-progress protection, success navigation, or localized error feedback.

## Implementation Steps

1. Add a transaction-aware aggregate update path and use it from `deleteReceipt`.
2. Emit `DatabaseUpdateBus` only after the deletion transaction commits.
3. Add localized EN/RU/PL confirmation, success, and safe generic failure text; regenerate localizations.
4. Wire the Receipt Details delete action through an injectable callback, require confirmation, prevent duplicate submissions, and return after success.
5. Add repository and widget tests, then run focused and full validation.
6. Record completion evidence here and in the master tracker.

## Affected Files

- `lib/data/aggregates_updater.dart`
- `lib/data/repositories/receipt_repository.dart`
- `lib/features/receipt_details/receipt_details_view.dart`
- `lib/features/receipt_details/widgets/receipt_details_content.dart`
- `lib/features/receipt_details/widgets/action_buttons.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ru.arb`
- `lib/l10n/app_pl.arb`
- generated `lib/l10n/app_localizations*.dart`
- `test/data/receipt_repository_test.dart`
- `test/features/receipt_details/receipt_details_view_test.dart`
- `docs/framework_refactoring_plan.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| A destructive action is invoked accidentally. | Require explicit confirmation and mark the action destructive. |
| Receipt and aggregate tables diverge after an error. | Perform deletion and affected-month aggregate updates in one SQLite transaction. |
| Repeated taps run multiple deletes. | Disable the delete action while its Future is pending. |
| Error details expose receipt data. | Use a generic localized failure message; do not log raw exceptions. |

## Tests And Checks

- [x] `flutter test test/data/receipt_repository_test.dart`
- [x] `flutter test test/features/receipt_details/receipt_details_view_test.dart`
- [x] `flutter test test/l10n/category_localizations_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] A receipt can be deleted only after confirmation from its details screen.
- [x] Receipt, line items, and affected aggregates remain consistent after a successful deletion.
- [x] Updates are broadcast only after a successful commit.
- [x] UI returns after success and exposes only localized safe messages.
- [x] EN/RU/PL ARB and generated localization files are synchronized.
- [x] Relevant tests and checks pass.
- [x] Master tracker and completion notes are updated; follow-up work is recorded.

## Completion Notes

- Completed on: 2026-08-26
- Tests run:
  - `flutter test test/data/receipt_repository_test.dart`
  - `flutter test test/features/receipt_details/receipt_details_view_test.dart`
  - `flutter test test/l10n/category_localizations_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Deletion applies to exactly one receipt from its details screen and has no undo in this package.
  - The receipt, line items, and affected aggregates are changed in one SQLite transaction; listener notification follows a successful commit only.
  - Failure feedback is generic and localized; raw database errors are neither logged nor displayed.
- Follow-ups:
  - Create a separate sub-plan for Settings “clear all data”, including its own irreversible-action safeguards.
  - Open-PDF and recategorization remain separate Receipt Details feature packages.
