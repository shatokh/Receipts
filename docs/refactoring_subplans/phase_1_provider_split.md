# Phase 1: Provider Split

## Master Plan Link

- Master phase: `docs/framework_refactoring_plan.md` section 7, `Этап 1. Разделить provider composition`
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-06-02

## Scope

- Split `lib/app/providers.dart` into focused provider groups.
- Keep `lib/app/providers.dart` as a backward-compatible barrel export.
- Preserve all public provider and notifier names.
- Keep behavior unchanged.
- Run analyze and tests after the mechanical split.

## Non-goals

- Do not introduce Riverpod code generation.
- Do not move feature-local provider usages in widgets yet.
- Do not introduce repository interfaces or application/use-case layer.
- Do not change import, database, settings, or UI behavior.

## Current State Check

- Files inspected:
  - `lib/app/providers.dart`
  - `lib/main.dart`
  - `lib/features/import/import_controller.dart`
  - `lib/features/*/*_view.dart`
  - `test/import_pipeline_test.dart`
- Existing behavior confirmed:
  - App code imports `package:receipts/app/providers.dart`.
  - Tests instantiate repositories directly in several places.
  - `settingsRepositoryProvider` is runtime-overridden in `main.dart`.
  - `filteredReceiptsProvider` currently mixes UI state, repository stream, and date formatting.
- Known gaps:
  - UI state providers can move closer to features later, but this phase keeps names exported through the app barrel.

## Implementation Steps

1. Create provider group files under `lib/app/providers/`.
2. Move repository providers without changing names.
3. Move platform providers without changing names.
4. Move settings/logging providers and notifier classes without changing names.
5. Move import/parser service providers without changing names.
6. Move data query providers and shared UI state providers without changing names.
7. Replace `lib/app/providers.dart` with exports.
8. Run formatter, analyze, and tests.
9. Update completion notes and master plan tracker.

## Affected Files

- `lib/app/providers.dart`
- `lib/app/providers/repository_providers.dart`
- `lib/app/providers/platform_providers.dart`
- `lib/app/providers/settings_providers.dart`
- `lib/app/providers/service_providers.dart`
- `lib/app/providers/data_query_providers.dart`
- `lib/app/providers/ui_state_providers.dart`
- `docs/framework_refactoring_plan.md`
- `docs/refactoring_subplans/phase_1_provider_split.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Import cycles between provider groups. | Keep dependencies one-way: services depend on repository/platform/settings, query/UI providers depend on repositories. |
| Existing imports break. | Keep `lib/app/providers.dart` as barrel export. |
| Behavior changes during split. | Move code mechanically and run full tests. |

## Tests And Checks

- [x] `flutter analyze`
- [x] `flutter test`

## Definition Of Done

- [x] `lib/app/providers.dart` is a compatibility barrel.
- [x] Public provider/notifier names are unchanged.
- [x] Provider groups have clear ownership.
- [x] Analyze and tests pass.
- [x] Master plan tracker updated.
- [x] Follow-up work recorded.

## Completion Notes

- Completed on: 2026-06-02
- Tests run:
  - `flutter analyze`
  - `flutter test`
- Decisions made:
  - Keep `lib/app/providers.dart` as the compatibility barrel for existing imports.
  - Split providers into repository, platform, settings/logging, service, data query, and UI state groups.
  - Preserve all public provider and notifier names.
- Follow-ups:
  - Move feature-local UI state closer to features in a later UI/provider cleanup phase.
  - Add provider composition smoke tests if future provider changes become behavioral rather than mechanical.
