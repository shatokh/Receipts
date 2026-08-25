---
name: receipts-l10n
description: Add or update localized UI text in the Receipts Flutter app. Use when changing visible strings, ARB files, placeholders, plurals, locale behavior, date formatting, or currency formatting.
---

# Receipts L10n

Use this skill for user-facing text in widgets, snackbars, dialogs, labels, empty states, errors, and navigation.

## Rules

- Put visible strings in all supported ARB files:
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_ru.arb`
  - `lib/l10n/app_pl.arb`
- Include ARB metadata for placeholders and plurals.
- Do not hardcode visible English/Russian/Polish strings directly in widgets.
- Use `AppLocalizations.of(context)!` in UI code.
- Use helpers in `lib/l10n/app_localizations_extensions.dart` for month labels when they fit the use case.
- Use `intl` with the current locale for dates and currency.

## Generated Files

Regenerate localizations through Flutter tooling after ARB changes:

```powershell
flutter gen-l10n
```

Commit ARB and generated files together:

- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_en.dart`
- `lib/l10n/app_localizations_ru.dart`
- `lib/l10n/app_localizations_pl.dart`

Do not manually edit generated localization files unless generation is unavailable and the tradeoff is documented in the sub-plan or PR notes.

## Validation

Run:

```powershell
flutter test test/l10n/category_localizations_test.dart
flutter test
```
