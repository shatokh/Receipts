# Receipts AI Instructions

`AGENTS.md` is the primary source of truth for AI coding rules in this repository. Follow it for architecture, privacy, localization, testing, database, import pipeline, and epic planning rules.

This file is only a compact mirror for tools that read GitHub Copilot instructions.

## Core Rules

- Keep receipt processing offline-first and on-device.
- Do not log raw receipt text, line items, totals, NIP values, file paths/URIs, source payloads, or PDF text.
- Put user-facing strings in all supported ARB files: `app_en.arb`, `app_ru.arb`, and `app_pl.arb`; regenerate and commit `app_localizations*.dart` together.
- Keep platform integrations behind interfaces/providers so tests can override them.
- Keep `domain/` pure Dart. Do not introduce Flutter, Riverpod, sqflite, platform channels, or generated l10n dependencies there.
- Add app-wide providers under focused files in `lib/app/providers/`; keep `lib/app/providers.dart` as the compatibility barrel.
- Put app-flow orchestration in `lib/application/` when it is not purely UI state.
- Repositories currently own receipt writes, aggregate updates, and `DatabaseUpdateBus` notifications.

## Checks

- Default fast check: `flutter test`.
- Broad changes: `flutter analyze` and `flutter test`.
- Current CI coverage gate: `dart run tool/test_with_coverage.dart --min-coverage=50`.
- Android integration tests are manual-only; do not add them to coverage.
