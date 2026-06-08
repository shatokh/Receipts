# Phase 7: Receipt Details View Model

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 7. View models для экранов аналитики`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-05

## Scope

- Introduce a focused `ReceiptDetailsViewModel` for receipt details presentation mapping.
- Move UI-ready receipt header, VAT summary, and line-item row mapping out of receipt details widgets.
- Keep `ReceiptDetailsView` provider orchestration and existing route behavior unchanged.
- Keep existing localized text, placeholder action buttons, loading/error states, and visual layout unchanged.
- Add focused unit tests for the view model mapping.

## Non-goals

- Do not implement open-PDF, recategorization, delete, or clear-data behavior in this work package.
- Do not change database schema, repositories, or import pipeline.
- Do not move `receiptDetailsProvider` or introduce repository ports.
- Do not add or change user-facing localization strings.
- Do not expose raw `sourceUri`, file paths, NIP values, or line-item payloads in logs/tests.

## Current State Check

- Files inspected:
  - `lib/features/receipt_details/receipt_details_view.dart`
  - `lib/features/receipt_details/widgets/receipt_details_content.dart`
  - `lib/features/receipt_details/widgets/receipt_header.dart`
  - `lib/features/receipt_details/widgets/items_table.dart`
  - `lib/features/receipt_details/widgets/vat_summary.dart`
  - `lib/features/receipt_details/widgets/action_buttons.dart`
  - `test/features/receipt_details/receipt_details_view_test.dart`
- Existing behavior confirmed:
  - `ReceiptDetailsView` is already a thin Riverpod wrapper around `receiptDetailsProvider(receiptId)`.
  - `ReceiptDetailsContent` owns screen layout and back navigation.
  - `ReceiptHeader` formats merchant, purchase timestamp, and total gross.
  - `ItemsTable` maps `LineItem` to quantity/unit-price, VAT, total, discount styling, and empty-state rendering.
  - `VatSummary` formats total VAT.
  - Action buttons are intentionally placeholder snackbars.
- Known gaps:
  - Presentation mapping is still mixed into widgets.
  - Existing widget smoke test covers happy-path rendering but not mapping edge cases such as discounts or fractional quantities.

## Implementation Steps

1. Add `lib/features/receipt_details/receipt_details_view_model.dart`.
2. Define small UI-ready data classes for:
   - receipt header summary;
   - line-item row presentation;
   - VAT summary;
   - optional aggregate flags such as `hasLineItems`.
3. Move pure mapping rules into `ReceiptDetailsViewModel.fromDetails`.
4. Keep formatting ownership narrow:
   - either keep currency/date formatter calls in widgets for this package;
   - or pass preconfigured `DateFormat`/`NumberFormat` into the view model factory if the mapping benefit is worth it.
   - Do not make the view model depend on `BuildContext` or generated localization classes.
5. Update receipt details widgets to render the view model while preserving layout and strings.
6. Add `test/features/receipt_details/receipt_details_view_model_test.dart`.
7. Run formatter, focused view model/widget tests, analyzer, and full test suite.
8. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `lib/features/receipt_details/receipt_details_view.dart`
- `lib/features/receipt_details/receipt_details_view_model.dart`
- `lib/features/receipt_details/widgets/receipt_details_content.dart`
- `lib/features/receipt_details/widgets/receipt_header.dart`
- `lib/features/receipt_details/widgets/items_table.dart`
- `lib/features/receipt_details/widgets/vat_summary.dart`
- `test/features/receipt_details/receipt_details_view_model_test.dart`
- `test/features/receipt_details/receipt_details_view_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_7_receipt_details_view_model.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| View model broadens into feature work for open PDF/delete/recategorization. | Keep action buttons unchanged and record feature behavior as follow-up only. |
| Formatting changes alter visible totals/dates. | Preserve existing `en_US`, `PLN `, `yyyy-MM-dd HH:mm`, quantity, VAT, and discount formatting unless explicitly tested. |
| View model depends on Flutter/localization. | Keep mapping pure Dart; pass primitive formatter outputs or formatter dependencies explicitly if needed. |
| Tests accidentally include sensitive receipt details. | Use generic fixture names and no source URIs, NIP values, or file paths. |

## Tests And Checks

- [x] `dart format lib/features/receipt_details/receipt_details_view.dart lib/features/receipt_details/receipt_details_view_model.dart lib/features/receipt_details/widgets test/features/receipt_details/receipt_details_view_model_test.dart test/features/receipt_details/receipt_details_view_test.dart`
- [x] `flutter test test/features/receipt_details/receipt_details_view_model_test.dart test/features/receipt_details/receipt_details_view_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Receipt details presentation mapping lives in `ReceiptDetailsViewModel`.
- [x] Receipt details UI behavior, strings, and placeholder actions are unchanged.
- [x] Focused view model tests cover regular items, discount/negative rows, fractional quantities, empty items, header, and VAT summary mapping.
- [x] Existing receipt details widget smoke test passes.
- [x] Analyzer and full tests pass or any existing unrelated failures are documented.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-05
- Tests run:
  - `dart format lib/features/receipt_details/receipt_details_view.dart lib/features/receipt_details/receipt_details_view_model.dart lib/features/receipt_details/widgets test/features/receipt_details/receipt_details_view_model_test.dart test/features/receipt_details/receipt_details_view_test.dart`
  - `flutter test test/features/receipt_details/receipt_details_view_model_test.dart test/features/receipt_details/receipt_details_view_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Keep `ReceiptDetailsViewModel` pure Dart with `intl` formatting and no `BuildContext`/l10n dependency.
  - Preserve existing date/currency/quantity/VAT formatting, including negative currency formatting from `NumberFormat.currency`.
  - Keep feature actions and persistence changes out of scope.
- Follow-ups:
  - Create a separate sub-plan before implementing open-PDF, recategorization, delete, or other receipt details actions.
