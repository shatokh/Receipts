# Phase 3: Import Use Case Layer

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 3. Выделить application/use-case слой`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-02

## Scope

- Introduce an `application/import` use-case layer for import orchestration.
- Keep existing import behavior unchanged:
  - file hash duplicate detection
  - PDF extraction
  - JSON/text fallback
  - heuristic duplicate detection
  - receipt and line item persistence
  - aggregate updates through existing repository behavior
  - user-safe import error messages
- Keep `ImportService` as a compatibility wrapper or thin delegator for current providers/controllers.
- Add or update focused tests if behavior surface changes.

## Non-goals

- Do not add bulk import UX changes.
- Do not change duplicate detection rules.
- Do not move aggregate ownership out of repositories in this phase.
- Do not introduce repository interfaces/ports yet.
- Do not change `FileImportService`, `PdfTextExtractor`, or Android platform APIs.

## Current State Check

- Files inspected:
  - `lib/features/import/import_service.dart`
  - `lib/features/import/import_controller.dart`
  - `lib/app/providers/service_providers.dart`
  - `test/import_pipeline_test.dart`
  - `test/test_infra/fakes/fake_file_import_service.dart`
- Existing behavior confirmed:
  - `ImportController` reads `importServiceProvider` and calls `importMany`.
  - `ImportService.importOne` currently owns import orchestration.
  - `ReceiptRepository.insertReceiptWithItems` owns aggregate updates and update bus emission after successful insert.
  - Privacy guardrails from Phase 0 are already in place.
- Known gaps:
  - No formal application layer exists yet.
  - Repository interfaces/ports are not defined.

## Architecture Decisions For This Phase

- Repository dependency strategy: temporarily allow `application/import` to depend on concrete repositories. Introducing repository interfaces is deferred to a later architecture pass only if real duplication or test pressure appears.
- Aggregate ownership strategy: repositories remain responsible for aggregate updates and `DatabaseUpdateBus` notifications during this phase. Use cases call repository write methods and do not duplicate aggregate updates.
- Compatibility strategy: keep `ImportService` public API stable and make it delegate to the new use case so existing controllers/providers/tests keep compiling with minimal churn.

## Implementation Steps

1. Add `lib/application/import/import_receipt_use_case.dart`.
2. Move orchestration logic from `ImportService` into the use case.
3. Keep parsing/error helper behavior equivalent and privacy-safe.
4. Change `ImportService` into a thin wrapper around the use case.
5. Update `importServiceProvider` construction if needed.
6. Run focused import pipeline tests and full suite.
7. Update completion notes and master plan tracker.

## Affected Files

- `lib/application/import/import_receipt_use_case.dart`
- `lib/features/import/import_service.dart`
- `lib/app/providers/service_providers.dart`
- `test/import_pipeline_test.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_3_import_use_case_layer.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Import behavior changes during move. | Keep `test/import_pipeline_test.dart` focused cases passing. |
| Aggregate updates duplicate or disappear. | Keep aggregate ownership in `ReceiptRepository` for this phase. |
| Privacy guardrails regress. | Preserve Phase 0 tests and safe error mapping. |
| Application layer becomes over-abstracted. | Add one use case first, no ports/interfaces yet. |

## Tests And Checks

- [x] `flutter test test/import_pipeline_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] Import orchestration lives in `application/import`.
- [x] `ImportService` remains compatible for current callers.
- [x] Existing import behavior is preserved.
- [x] Aggregate ownership remains clear and documented.
- [x] Analyze and tests pass.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-02
- Tests run:
  - `flutter test test/import_pipeline_test.dart`
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Added `ImportReceiptUseCase` under `lib/application/import/`.
  - Kept `ImportService` as a thin compatibility wrapper for existing providers/controllers/tests.
  - Kept aggregate updates and `DatabaseUpdateBus` notifications owned by repositories for this phase.
  - Deferred repository interfaces/ports because the current concrete repository dependency keeps the migration smaller.
- Follow-ups:
  - Consider direct use-case tests after `ImportService` compatibility wrapper is no longer the main test seam.
  - Repository ports/interfaces remain optional future work, not required by this phase.
