# Formatter Ownership Cleanup

## Master Plan Link

- Master phase: follow-up from `docs/refactoring_subplans/phase_7_closeout.md`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-08

## Scope

- Centralize repeated UI formatter construction for receipt currency and receipt timestamps.
- Preserve the current visible formatting exactly:
  - currency: `NumberFormat.currency(locale: 'en_US', symbol: 'PLN ', decimalDigits: 2)`
  - receipt timestamp: `yyyy-MM-dd HH:mm`
  - receipt search date: `yyyy-MM-dd`
- Refactor existing dashboard, month, receipts, receipt details, and filter-state consumers to use the shared helper.
- Add focused tests for the formatter helper.

## Non-goals

- Do not change locale policy or switch formatting to the active app locale.
- Do not change generated localization files or ARB strings.
- Do not change business logic, filtering behavior, or UI layout.
- Do not raise coverage thresholds in this package.

## Current State Check

- Files inspected:
  - `lib/features/dashboard/widgets/kpi_cards.dart`
  - `lib/features/dashboard/widgets/quick_insights.dart`
  - `lib/features/dashboard/widgets/monthly_chart.dart`
  - `lib/features/dashboard/widgets/top_categories_section.dart`
  - `lib/features/month/month_view.dart`
  - `lib/features/month/widgets/category_breakdown.dart`
  - `lib/features/month/widgets/receipt_list.dart`
  - `lib/features/receipts/widgets/receipts_list.dart`
  - `lib/features/receipt_details/receipt_details_view_model.dart`
  - `lib/application/receipts/receipts_filter_state.dart`
- Existing behavior confirmed:
  - Multiple widgets construct the same PLN currency formatter.
  - Receipt row/details timestamps use the same `yyyy-MM-dd HH:mm` pattern.
  - Receipt search filtering uses `yyyy-MM-dd`.

## Implementation Steps

1. Add a small shared formatter helper under `lib/core/formatting/`.
2. Replace duplicated formatter constructors with the helper.
3. Keep dependency injection seams where view models accept formatter overrides.
4. Add focused unit tests for currency, timestamp, and search-date formatting.
5. Run formatter, focused tests, analyzer, and full test suite.
6. Update this sub-plan and the master plan tracker with completion evidence.

## Affected Files

- `lib/core/formatting/app_formatters.dart`
- `lib/application/receipts/receipts_filter_state.dart`
- `lib/features/dashboard/widgets/*.dart`
- `lib/features/month/*.dart`
- `lib/features/receipts/widgets/receipts_list.dart`
- `lib/features/receipt_details/receipt_details_view_model.dart`
- `test/core/formatting/app_formatters_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/formatter_ownership_cleanup.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Central helper accidentally changes visible formatting. | Assert exact representative outputs in focused tests. |
| Helper grows into locale policy work. | Keep this package limited to preserving existing formats. |
| View model tests lose override flexibility. | Keep optional formatter parameters in view model factories. |

## Tests And Checks

- [x] `dart format <changed dart files>`
- [x] `flutter test test/core/formatting/app_formatters_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Repeated formatter constructors are replaced by a shared helper.
- [x] Existing visible formatting is preserved.
- [x] Focused formatter tests pass.
- [x] Analyzer and full tests pass.
- [x] Master plan tracker updated.

## Completion Notes

- Completed on: 2026-06-08
- Tests run:
  - `dart format <changed dart files>`
  - `flutter test test/core/formatting/app_formatters_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Centralize existing receipt currency, receipt timestamp, and receipt search date formats in `AppFormatters`.
  - Preserve the previous output exactly and keep broader locale-policy changes out of this package.
- Follow-ups:
  - Consider active-locale currency/date formatting later as a product decision, not as framework cleanup.
