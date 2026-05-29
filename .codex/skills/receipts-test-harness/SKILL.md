---
name: receipts-test-harness
description: Write reliable tests for the Receipts Flutter app. Use when adding or updating unit, widget, repository, parser, import pipeline, localization, or integration tests.
---

# Receipts Test Harness

Use this skill when adding or fixing tests under `test/` or `integration_test/`.

## Unit And Repository Tests

- Use `bootstrapTestEnvironment`, `TestAppHarness`, or `createTestContainer` from `test/helpers/test_environment.dart`.
- Use provider overrides for platform services and runtime-only dependencies.
- Use fakes from `test/test_infra/fakes/` or add small test-local fakes when narrower.
- Do not call Android MethodChannels from unit tests.
- Clean up database state through the harness; do not share a database between tests.

## Assertions

- Use `closeTo` for monetary `double` values.
- Assert both status and message for import failures/duplicates when behavior matters.
- For parser tests, assert date, total, VAT, item count, representative items, merchant, and categories.

## Integration Tests

- Use `integration_test/` for full app flows that need a device or emulator.
- Prefer existing helpers such as `pumpAndSettleSafe` and `waitForFinder` over arbitrary delays.
- See `README_TESTING.md` for Android emulator setup and helper scripts.

## Commands

```powershell
flutter test
dart run tool/test_with_coverage.dart
.\tool\it_android.ps1
```
