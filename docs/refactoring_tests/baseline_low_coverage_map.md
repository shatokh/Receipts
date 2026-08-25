# Baseline And Low-Coverage Map

## Status

- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-23
- Parent plan: `docs/refactoring_tests/testing_plan.md`, Package 1

## Scope

- Run the current fast quality checks.
- Measure the current unit/widget/repository coverage baseline.
- Record the lowest-covered packages and files so the next test-hardening work can target real gaps.

## Non-goals

- Do not change production code.
- Do not raise the CI coverage threshold in this package.
- Do not run Android emulator integration tests.
- Do not treat this measurement as a clean-branch baseline while unrelated dirty files are present.

## Current State Check

Files inspected:

- `tool/test_with_coverage.dart`
- `coverage/lcov.info`
- `docs/refactoring_tests/testing_plan.md`

Workspace note:

- Baseline was measured on the current working tree, which already had unrelated dirty files outside this package:
  - `.codex/skills/receipts-l10n/SKILL.md`
  - `.github/copilot-instructions.md`
  - `AGENTS.md`
  - `lib/domain/parsing/receipt_parser.dart`
  - `test/receipt_parser_new_format_test.dart`
- The parser changes add two parser tests, so this baseline should be treated as current-workspace evidence, not a canonical clean-main baseline.

## Results

Commands run:

- `flutter analyze`
- `flutter test`
- `dart run tool/test_with_coverage.dart --min-coverage=0`

Outcomes:

- `flutter analyze`: passed, no issues.
- `flutter test`: passed, 66 tests.
- Coverage helper: passed.
- Coverage baseline: 50.63% line coverage, 1496/2955 lines.
- Coverage run seed: `3537257059`.

## Low-Coverage Areas

Area-level coverage from `coverage/lcov.info`:

| Area | Coverage | Lines hit | Lines found |
| --- | ---: | ---: | ---: |
| `lib/theme.dart` | 0.00% | 0 | 13 |
| `lib/platform` | 2.17% | 1 | 46 |
| `lib/l10n` | 17.23% | 87 | 505 |
| `lib/app` | 31.03% | 27 | 87 |
| `lib/features` | 49.44% | 569 | 1151 |
| `lib/data` | 66.44% | 291 | 438 |
| `lib/application` | 70.09% | 75 | 107 |
| `lib/domain` | 72.87% | 384 | 527 |
| `lib/core` | 76.54% | 62 | 81 |

Lowest-covered notable files:

| File | Coverage | Lines hit | Lines found |
| --- | ---: | ---: | ---: |
| `lib/platform/pdf_text_extractor/android_pdf_text_extractor.dart` | 0.00% | 0 | 43 |
| `lib/l10n/app_localizations_pl.dart` | 0.00% | 0 | 160 |
| `lib/l10n/app_localizations_ru.dart` | 0.00% | 0 | 160 |
| `lib/features/dashboard/widgets/monthly_chart.dart` | 0.00% | 0 | 61 |
| `lib/features/dashboard/widgets/quick_insights.dart` | 0.00% | 0 | 51 |
| `lib/features/dashboard/widgets/top_categories_section.dart` | 0.00% | 0 | 50 |
| `lib/data/repositories/category_repository.dart` | 0.00% | 0 | 30 |
| `lib/features/receipts/widgets/receipts_list.dart` | 0.00% | 0 | 23 |
| `lib/features/dashboard/widgets/kpi_cards.dart` | 0.00% | 0 | 34 |
| `lib/features/import/import_view.dart` | 21.53% | 31 | 144 |

## Decisions

- Keep the Sonar coverage threshold at `--min-coverage=50` for now.
- Do not raise the gate from a 50.63% current-workspace baseline; the margin is too small.
- Prioritize Package 2 and Package 4 next:
  - Package 2 because import/parser behavior is product-critical.
  - Package 4 because `lib/features` is the largest low-coverage area and has many smoke-only widget tests.
- Do not chase generated localization file coverage directly. Prefer ARB/localization behavior tests and consider excluding generated localization files from coverage only as a separate policy decision.

## Risks

| Risk | Mitigation |
| --- | --- |
| Coverage was measured on a dirty workspace. | Record dirty files and remeasure after parser/instruction changes are resolved. |
| Raising gate now would make CI brittle. | Keep `--min-coverage=50` until meaningful tests raise baseline with margin. |
| Low l10n generated coverage distorts prioritization. | Target behavior tests first; decide generated-file coverage policy separately. |
| Platform implementation coverage is low because MethodChannel code is hard to unit test. | Keep platform behind providers and cover real behavior through manual integration smoke only when needed. |

## Tests And Checks

- [x] `flutter analyze`
- [x] `flutter test`
- [x] `dart run tool/test_with_coverage.dart --min-coverage=0`

## Definition Of Done

- [x] Current coverage baseline recorded.
- [x] Low-coverage area map recorded.
- [x] CI threshold decision recorded.
- [x] Dirty workspace caveat recorded.
- [x] Next packages identified.

## Completion Notes

- Completed on: 2026-06-23
- Follow-ups:
  - Re-run baseline after unrelated dirty parser/instruction changes are resolved.
  - Continue with Package 2: import and parser hardening.
  - Continue with Package 4 after Package 2 or in parallel if UI-only changes are preferred.
