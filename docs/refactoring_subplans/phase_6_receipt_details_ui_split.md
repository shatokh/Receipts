# Phase 6: Receipt Details UI Split

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 6. Разделить крупные UI файлы`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-04

## Scope

- Add minimal `ReceiptDetailsView` widget smoke coverage before splitting the file.
- Split `lib/features/receipt_details/receipt_details_view.dart` into smaller feature-local widget files.
- Keep details provider usage, route behavior, localized text, layout, formatting, loading/error states, and action snackbars unchanged.

## Non-goals

- Do not add delete/open-PDF/recategorization behavior in this work package.
- Do not introduce `ReceiptDetailsViewModel`.
- Do not redesign the receipt details UI.
- Do not add or change user-facing localization strings.

## Current State Check

- Files inspected:
  - `lib/features/receipt_details/receipt_details_view.dart`
  - `lib/app/router.dart`
  - `lib/app/providers/data_query_providers.dart`
  - `lib/domain/models/receipt_details.dart`
- Existing behavior confirmed:
  - The actual screen path is `lib/features/receipt_details/receipt_details_view.dart`, not `lib/features/receipts/receipt_details_view.dart` from the broad master-plan wording.
  - `ReceiptDetailsView` consumes `receiptDetailsProvider(receiptId)`.
  - The file mixes loading/error states, screen content, header, items table, VAT summary, and placeholder action buttons.
- Known gaps:
  - No `ReceiptDetailsView` smoke test exists yet.
  - Action buttons are still placeholders and intentionally remain unchanged.

## Implementation Steps

1. Add `test/features/receipt_details/receipt_details_view_test.dart` for happy-path rendering with provider overrides.
2. Create `lib/features/receipt_details/widgets/` files for states, content, header, items table, VAT summary, and action buttons.
3. Move private widget implementations out of `receipt_details_view.dart` with behavior-preserving renames where import visibility requires public classes.
4. Keep provider orchestration in `receipt_details_view.dart`.
5. Run formatter, focused Receipt Details widget test, analyzer, and full test suite.
6. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `lib/features/receipt_details/receipt_details_view.dart`
- `lib/features/receipt_details/widgets/receipt_details_states.dart`
- `lib/features/receipt_details/widgets/receipt_details_content.dart`
- `lib/features/receipt_details/widgets/receipt_header.dart`
- `lib/features/receipt_details/widgets/items_table.dart`
- `lib/features/receipt_details/widgets/vat_summary.dart`
- `lib/features/receipt_details/widgets/action_buttons.dart`
- `test/features/receipt_details/receipt_details_view_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_6_receipt_details_ui_split.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Details screen behavior changes during mechanical extraction. | Keep code bodies unchanged except class names/imports; run focused widget smoke and full tests. |
| Back/navigation behavior breaks after extraction. | Keep `context.pop()` in the content widget and do not change router setup. |
| Test output exposes receipt-like sensitive data. | Use generic fixture names and avoid raw source URIs/NIP/file paths. |

## Tests And Checks

- [x] `dart format lib/features/receipt_details/receipt_details_view.dart lib/features/receipt_details/widgets test/features/receipt_details/receipt_details_view_test.dart`
- [x] `flutter test test/features/receipt_details/receipt_details_view_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Receipt Details has a basic widget smoke test.
- [x] Receipt Details private widget implementations are moved to feature-local widget files.
- [x] Receipt Details behavior and localized strings are unchanged.
- [x] Focused Receipt Details widget test passes.
- [x] Analyzer and full tests pass or any existing unrelated failures are documented.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-04
- Tests run:
  - `dart format lib/features/receipt_details/receipt_details_view.dart lib/features/receipt_details/widgets test/features/receipt_details/receipt_details_view_test.dart`
  - `flutter test test/features/receipt_details/receipt_details_view_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Add a focused happy-path smoke test before extracting widgets because Receipt Details had no screen-level widget coverage.
  - Keep provider orchestration in `receipt_details_view.dart`.
  - Move rendering/state widgets into feature-local files with public wrapper names only where imports require them.
  - Keep placeholder action button behavior unchanged.
- Follow-ups:
  - Create a separate sub-plan before implementing open-PDF, recategorization, or delete actions.
  - Create a separate sub-plan before splitting `settings_view.dart`.
