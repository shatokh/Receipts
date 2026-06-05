import 'package:sqflite/sqflite.dart';

import 'package:receipts/domain/category_definitions.dart';

Future<void> upgradeDatabase(
    Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2 && newVersion >= 2) {
    await migrateCategoriesToDefinitions(db);
  }
}

Future<void> migrateCategoriesToDefinitions(Database db) async {
  await db.transaction((txn) async {
    for (final definition in categoryDefinitions) {
      await txn.execute(
        'INSERT OR IGNORE INTO categories (id, name) VALUES (?, ?)',
        [definition.id, definition.fallbackLabel],
      );
      await txn.update(
        'categories',
        {'name': definition.fallbackLabel},
        where: 'id = ?',
        whereArgs: [definition.id],
      );

      for (final legacyId in definition.legacyIds) {
        final legacyTotals = await txn.query(
          'category_month_totals',
          columns: ['year', 'month', 'total'],
          where: 'category_id = ?',
          whereArgs: [legacyId],
        );

        for (final row in legacyTotals) {
          final year = row['year'] as int;
          final month = row['month'] as int;
          final total = (row['total'] as num?)?.toDouble() ?? 0.0;

          await txn.execute(
            '''
            INSERT INTO category_month_totals (category_id, year, month, total)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(category_id, year, month) DO UPDATE SET
              total = category_month_totals.total + excluded.total
            '''
                .trim(),
            [definition.id, year, month, total],
          );
        }

        await txn.delete(
          'category_month_totals',
          where: 'category_id = ?',
          whereArgs: [legacyId],
        );

        await txn.update(
          'line_items',
          {'category_id': definition.id},
          where: 'category_id = ?',
          whereArgs: [legacyId],
        );

        await txn.delete(
          'categories',
          where: 'id = ?',
          whereArgs: [legacyId],
        );
      }
    }
  });
}
