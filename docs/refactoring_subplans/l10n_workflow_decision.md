# L10n Workflow Decision

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 8, `L10n workflow decision for EN/RU/PL`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-02

## Scope

- Decide whether generated `app_localizations*.dart` files remain source-controlled.
- Document the EN/RU/PL localization workflow before larger refactor/UI work.
- Align workflow docs with `l10n.yaml`, current generated files, and project instructions.
- Run focused l10n validation.

## Non-goals

- Do not add, remove, or translate UI strings in this work package.
- Do not regenerate localization files unless the workflow check shows they are stale.
- Do not change supported locales.
- Do not introduce a CI sync check yet; document it as a future quality-gate option if needed.

## Current State Check

- Files inspected:
  - `l10n.yaml`
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_ru.arb`
  - `lib/l10n/app_pl.arb`
  - `lib/l10n/app_localizations.dart`
  - `lib/l10n/app_localizations_en.dart`
  - `lib/l10n/app_localizations_ru.dart`
  - `lib/l10n/app_localizations_pl.dart`
  - `test/l10n/category_localizations_test.dart`
- Existing behavior confirmed:
  - `synthetic-package: false` writes generated localizations into `lib/l10n`.
  - Generated EN/RU/PL localization files are currently source-controlled.
  - `AppLocalizations.supportedLocales` includes EN, PL, and RU.
- Known gaps:
  - The workflow was implicit before this work package.
  - The l10n skill text still mentions EN/RU only, but project instructions now require EN/RU/PL.

## Implementation Steps

1. Add a small l10n workflow doc.
2. State the decision: keep generated localization files source-controlled for now.
3. Document the command and commit expectations: ARB -> generate -> commit ARB and generated files together.
4. Run focused l10n test.
5. Update completion notes and master plan tracker.

## Affected Files

- `docs/l10n_workflow.md`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/l10n_workflow_decision.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Generated files drift from ARB files. | Document generation command and future CI sync check. |
| Instructions disagree on locale set. | Treat AGENTS.md and master plan EN/RU/PL rule as current project rule. |
| Workflow doc becomes stale. | Keep master tracker entry and update doc when generated-file policy changes. |

## Tests And Checks

- [x] `flutter test test/l10n/category_localizations_test.dart`

## Definition Of Done

- [x] Generated localization file policy is documented.
- [x] EN/RU/PL ARB and generated file workflow is documented.
- [x] Focused l10n test passes.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-02
- Tests run:
  - `flutter test test/l10n/category_localizations_test.dart`
- Decisions made:
  - Keep generated `app_localizations*.dart` files source-controlled for now.
  - Localization changes must update EN/RU/PL ARB files, run `flutter gen-l10n`, and commit ARB plus generated files together.
  - Do not add a CI generated-file drift check yet; document it as a future quality gate option.
- Follow-ups:
  - Add CI sync check later if generated localization drift becomes recurring.
  - The bundled `receipts-l10n` skill text still mentions EN/RU only; project `AGENTS.md` and `docs/l10n_workflow.md` now define EN/RU/PL as the current rule.
