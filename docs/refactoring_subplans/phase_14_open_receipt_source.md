# Phase 14: Open Receipt Source

## Master Plan Link

- Master work package: `docs/framework_refactoring_plan.md` section 8, feature work
- Status: complete
- Owner/agent: Codex
- Last updated: 2026-08-26

## Scope

- Replace the Receipt Details Open PDF placeholder with an explicit open-source action.
- Add an overrideable Dart platform interface and Android implementation that launches a system viewer for the persisted local/content URI.
- Grant read access only to the URI being opened and handle unavailable sources with generic localized UI feedback.
- Disable the action when a receipt has no stored source URI; test UI wiring through a callback override.

## Non-goals

- Do not upload, sync, copy, log, or display source paths/URIs.
- Do not build an in-app PDF renderer, modify receipt parsing, or add a PDF viewer dependency.
- Do not guarantee availability if Android revoked access to the original document or no compatible viewer is installed.
- Do not implement a JSON/source-editor workflow; the action delegates source handling to the operating system.

## Current State Check

Files inspected:

- `lib/application/import/import_receipt_use_case.dart`
- `lib/domain/models/receipt.dart`
- `lib/features/import/file_import_service.dart`
- `lib/features/receipt_details/receipt_details_view.dart`
- `lib/features/receipt_details/widgets/action_buttons.dart`
- `android/app/src/main/kotlin/app/receipts/MainActivity.kt`
- `android/app/src/main/AndroidManifest.xml`

Existing behavior confirmed:

- Successful imports persist the selected source URI in `receipts.source_uri`.
- Receipt Details has an Open PDF button that only shows a placeholder snackbar.
- Android already exposes a MethodChannel for PDF extraction but no platform interface for opening a source file.
- No URI/path is displayed in the current receipt details UI.

Known gaps:

- There is no platform abstraction or Android intent flow to open the persisted source.
- Raw filesystem paths require a `FileProvider` URI before they can be handed to another Android app.
- A persisted content URI may later be unavailable, which must remain a user-safe recoverable error.

## Implementation Steps

1. Add an overrideable receipt-source opener interface/provider and Android MethodChannel implementation.
2. Add Android intent handling, MIME resolution, URI-specific read permission, and FileProvider support for local paths.
3. Wire Receipt Details to enable Open PDF only when a source URI exists and prevent duplicate open attempts.
4. Add localized safe failure text, regenerate localizations, and remove the placeholder text.
5. Add widget tests using an injected opener callback; run analyzer and the full fast suite.
6. Record completion evidence here and in the master tracker.

## Affected Files

- `lib/platform/receipt_source_opener/*`
- `lib/app/providers/platform_providers.dart`
- `lib/features/receipt_details/receipt_details_view.dart`
- `lib/features/receipt_details/widgets/receipt_details_content.dart`
- `lib/features/receipt_details/widgets/action_buttons.dart`
- `android/app/src/main/kotlin/app/receipts/MainActivity.kt`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/res/xml/receipt_file_paths.xml`
- `lib/l10n/app_*.arb`, generated localizations
- `test/features/receipt_details/receipt_details_view_test.dart`
- `docs/framework_refactoring_plan.md`

## Risks

| Risk | Mitigation |
| --- | --- |
| Android no longer grants access to the original URI. | Surface a generic localized failure and never reveal the URI/path. |
| Sharing a raw `file://` URI causes a security exception. | Convert local paths through a non-exported FileProvider and grant only read access. |
| No compatible viewer is installed. | Catch Android activity resolution failures and present the same safe UI error. |
| Platform code is untestable in widget tests. | Keep it behind an overrideable provider and inject a callback in the view test. |
| Source URI leaks into logs or messages. | Do not log source values; native errors use fixed generic codes/messages. |

## Tests And Checks

- [x] `flutter test test/features/receipt_details/receipt_details_view_test.dart`
- [x] `flutter test test/l10n/category_localizations_test.dart`
- [x] `flutter analyze`
- [x] `flutter test`
- [ ] Android manual smoke with a synthetic PDF and installed viewer (not run: no emulator/device connected).

## Definition Of Done

- [x] Open PDF launches the OS handler only when a persisted source exists.
- [x] Android grants read access only to the selected URI and supports content/local file sources.
- [x] Missing/unavailable sources show only generic localized feedback.
- [x] No source URI/path is logged or rendered.
- [x] EN/RU/PL ARB and generated files are synchronized.
- [x] Widget tests and fast checks pass; Android smoke status is recorded.
- [x] Master tracker and completion notes are updated; follow-ups are recorded.

## Completion Notes

- Completed on: 2026-08-26
- Tests run:
  - `flutter test test/features/receipt_details/receipt_details_view_test.dart`
  - `flutter test test/l10n/category_localizations_test.dart`
  - `flutter analyze`
  - `flutter test`
  - `android/gradlew.bat :app:processDebugMainManifest --console=plain`
  - `android/gradlew.bat :app:compileDebugKotlin --console=plain`
- Decisions made:
  - Open PDF is enabled only for receipts with a stored source URI; it delegates display to the OS instead of embedding a viewer.
  - Android shares only the selected URI with a temporary read grant. Raw local paths are converted through the app's non-exported FileProvider.
  - UI and platform errors are generic and localized; source URIs and paths are never logged or rendered.
- Follow-ups:
  - Manual Android smoke remains pending: start an emulator/device with a compatible PDF viewer, import a synthetic PDF, open its receipt details, and confirm the system chooser/viewer opens.
  - If imports must survive URI permission revocation, plan a separate source-copy/retention feature with explicit storage and privacy decisions.
