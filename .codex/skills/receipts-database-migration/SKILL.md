---
name: receipts-database-migration
description: Safely change the Receipts SQLite schema or repository persistence behavior. Use when editing DatabaseHelper, dbVersion, migrations, repository writes, aggregate tables, indexes, or SQL queries.
---

# Receipts Database Migration

Use this skill for work in `lib/data/database.dart` and `lib/data/repositories/`.

## Schema Change Checklist

1. Update the fresh schema in `_createDB`.
2. Increment `DatabaseHelper.dbVersion`.
3. Add an `_upgradeDB` path for existing databases.
4. Keep multi-table writes inside `db.transaction`.
5. Preserve or rebuild aggregate tables:
   - `monthly_totals`
   - `category_month_totals`
6. Add indexes for new query patterns that will run on dashboard, month, receipt list, or details screens.

## SQL Rules

- Use query parameters (`whereArgs` or raw query argument lists), not string interpolation.
- Keep receipt timestamps stored as epoch milliseconds.
- Filter months with `purchase_ts >= monthStart` and `purchase_ts < nextMonthStart`.
- Normalize legacy category ids through `normalizeCategoryId` when aggregating categories.

## Testing

- Use `TestAppHarness` or `createTestContainer` from `test/helpers/test_environment.dart`.
- Do not use the real app database path in tests.
- Test repository behavior and aggregate updates, not only raw SQL shape.

Useful commands:

```powershell
flutter test
dart run tool/test_with_coverage.dart
```
