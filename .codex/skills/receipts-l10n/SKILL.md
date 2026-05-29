---
name: receipts-l10n
description: Add or update localized UI text in the Receipts Flutter app. Use when changing visible strings, ARB files, placeholders, plurals, locale behavior, date formatting, or currency formatting.
---

# Receipts L10n

Use this skill for user-facing text in widgets, snackbars, dialogs, labels, empty states, errors, and navigation.

## Rules

- Put visible strings in both `lib/l10n/app_en.arb` and `lib/l10n/app_ru.arb`.
- Include ARB metadata for placeholders and plurals.
- Do not hardcode visible English/Russian strings directly in widgets.
- Use `AppLocalizations.of(context)!` in UI code.
- Use helpers in `lib/l10n/app_localizations_extensions.dart` for month labels when they fit the use case.
- Use `intl` with the current locale for dates and currency.

## Generated Files

Prefer regenerating localizations through Flutter tooling when possible. Do not manually edit `lib/l10n/app_localizations*.dart` unless generation is unavailable and the user accepts the tradeoff.

## Validation

Run:

```powershell
flutter test test/l10n/category_localizations_test.dart
flutter test
```
