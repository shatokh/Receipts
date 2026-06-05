# Localization Workflow

Receipts currently supports three locales:

- English: `lib/l10n/app_en.arb`
- Russian: `lib/l10n/app_ru.arb`
- Polish: `lib/l10n/app_pl.arb`

Generated localization files are written into `lib/l10n/` because `l10n.yaml` uses `synthetic-package: false`.

## Decision

Keep generated `app_localizations*.dart` files source-controlled for now.

This means localization changes must be committed as one coherent set:

1. Edit all relevant ARB files first:
   - `lib/l10n/app_en.arb`
   - `lib/l10n/app_ru.arb`
   - `lib/l10n/app_pl.arb`
2. Include placeholder metadata for interpolated strings and plurals.
3. Regenerate localizations:

   ```powershell
   flutter gen-l10n
   ```

4. Commit ARB and generated files together:
   - `lib/l10n/app_localizations.dart`
   - `lib/l10n/app_localizations_en.dart`
   - `lib/l10n/app_localizations_ru.dart`
   - `lib/l10n/app_localizations_pl.dart`

Do not manually edit generated localization files unless Flutter generation is unavailable and that tradeoff is documented in the sub-plan or PR notes.

## Validation

Run the focused localization test after localization changes:

```powershell
flutter test test/l10n/category_localizations_test.dart
```

For UI text changes, also run the relevant widget/import/parser tests and `flutter analyze`.

## Future CI Option

If generated file drift becomes a recurring issue, add a CI check that runs `flutter gen-l10n` and fails when generated output differs from the committed files.
