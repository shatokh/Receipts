# Phase 13: Re-categorize Receipt Line Item

## Master Plan Link

- Master work package: `docs/framework_refactoring_plan.md` section 8, feature work
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-08-26

## Scope

- Replace the Receipt Details re-categorization placeholder with selection of one line item and one built-in category.
- Persist the line item category and refresh affected category-month aggregates in the same SQLite transaction.
- Show the selected category on the receipt details item row and use localized category labels in the picker.
- Notify listeners only after commit; show localized safe success/failure feedback.
- Cover repository aggregate behavior and the widget picker flow.

## Non-goals

- Do not alter receipt totals, VAT, item amount, or purchase date.
- Do not add custom category creation, bulk re-categorization, category hierarchy editing, or parser rule changes.
- Do not change database schema or migrations.
- Do not implement Open PDF/source-file behavior.

## Current State Check

Files inspected:

- `lib/domain/models/line_item.dart`
- `lib/domain/category_definitions.dart`
- `lib/data/repositories/receipt_repository.dart`
- `lib/data/aggregates_updater.dart`
- `lib/features/receipt_details/receipt_details_view.dart`
- `lib/features/receipt_details/widgets/items_table.dart`
- `lib/features/receipt_details/widgets/action_buttons.dart`

Existing behavior confirmed:

- `line_items.category_id` is the source of per-item category assignment.
- `category_month_totals` is recalculated from line items and receipt month.
- The screen has a Re-categorize placeholder but no category or line-item picker.
- Category labels have an EN/RU/PL localization extension for the built-in category ids.

Known gaps:

- No repository operation updates a line item category and aggregate rows atomically.
- Receipt details do not display an item's category or offer a selection flow.

## Implementation Steps

1. Add a transaction-safe repository operation that normalizes the target category, updates one line item, and refreshes its purchase-month aggregates.
2. Surface line item id and category id in the pure receipt details view model.
3. Replace the action placeholder with localized item and category pickers; disable the action during a pending update.
4. Add localized UI messages, regenerate localization files, and avoid raw exception output.
5. Add repository and widget tests; run focused checks, analyzer, and the full fast suite.
6. Record completion evidence here and in the master tracker.

## Affected Files

- `lib/data/repositories/receipt_repository.dart`
- `lib/features/receipt_details/receipt_details_view.dart`
- `lib/features/receipt_details/receipt_details_view_model.dart`
- `lib/features/receipt_details/widgets/receipt_details_content.dart`
- `lib/features/receipt_details/widgets/action_buttons.dart`
- `lib/features/receipt_details/widgets/items_table.dart`
- `lib/l10n/app_en.arb`, `lib/l10n/app_ru.arb`, `lib/l10n/app_pl.arb`
- generated `lib/l10n/app_localizations*.dart`
- `test/data/receipt_repository_test.dart`
- `test/features/receipt_details/receipt_details_view_test.dart`
- `docs/framework_refactoring_plan.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Category totals diverge from item records. | Update the item and recompute the affected month inside one transaction. |
| A user changes the wrong item. | First show the item name and its current localized category, then show category options. |
| Target category is invalid or legacy. | Normalize category ids through the existing domain helper. |
| Repeated interaction starts overlapping writes. | Disable re-categorization while the update Future is pending. |
| Errors expose receipt data. | Show localized generic failure text and do not log raw errors. |

## Tests And Checks

- [x] `flutter test test/data/receipt_repository_test.dart`
- [x] `flutter test test/features/receipt_details/receipt_details_view_test.dart`
- [x] `flutter test test/l10n/category_localizations_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] A user can select a line item and replace its category with a built-in category.
- [x] The item and its affected category-month aggregate rows are consistent after commit.
- [x] Receipt totals remain unchanged.
- [x] The current item category and picker labels are localized.
- [x] Updates notify dependent screens only after success; safe error feedback is shown on failure.
- [x] EN/RU/PL ARB and generated files are synchronized.
- [x] Relevant tests and checks pass.
- [x] Master tracker and completion notes are updated; follow-ups are recorded.

## Completion Notes

- Completed on: 2026-08-26
- Tests run:
  - `flutter test test/data/receipt_repository_test.dart`
  - `flutter test test/features/receipt_details/receipt_details_view_test.dart`
  - `flutter test test/l10n/category_localizations_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Re-categorization applies to one line item because categories are stored in `line_items.category_id`; it does not modify receipt-level amounts.
  - The UI first selects a position, then one built-in localized category; the current category is visible on the item row.
  - Category updates and their affected aggregate rebuild run in one SQLite transaction and notify only after commit.
- Follow-ups:
  - Custom category management and bulk re-categorization require separate product decisions and plans.
  - Open-PDF/source-file support remains an independent Receipt Details feature package.
