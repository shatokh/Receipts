import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:receipts/data/database.dart';
import 'package:receipts/domain/category_definitions.dart';

import '../helpers/test_environment.dart';

void main() {
  late Directory dbDirectory;

  setUp(() async {
    await bootstrapTestEnvironment();
    dbDirectory = await Directory.systemTemp.createTemp(
      'reseipts_database_helper_test_',
    );
    databaseFactoryFfi.setDatabasesPath(dbDirectory.path);
    await DatabaseHelper.close();
  });

  tearDown(() async {
    await DatabaseHelper.close();
    DatabaseHelper.configureForTesting(databaseName: null);
    if (await dbDirectory.exists()) {
      await dbDirectory.delete(recursive: true);
    }
  });

  test('fresh database creates expected schema, indexes, and seed data',
      () async {
    DatabaseHelper.configureForTesting(databaseName: 'fresh.db');

    final db = await DatabaseHelper.database;

    final tables = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: "type = 'table' AND name NOT LIKE 'sqlite_%'",
    );
    expect(
        tables.map((table) => table['name']).toSet(),
        containsAll({
          'merchants',
          'categories',
          'receipts',
          'line_items',
          'monthly_totals',
          'category_month_totals',
        }));

    final indexes = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: "type = 'index' AND name NOT LIKE 'sqlite_%'",
    );
    expect(
        indexes.map((index) => index['name']).toSet(),
        containsAll({
          'idx_receipts_purchase_ts',
          'idx_receipts_total_gross',
          'idx_line_items_receipt_id',
        }));

    final categories = await db.query('categories');
    expect(categories, hasLength(categoryDefinitions.length));

    final merchants = await db.query(
      'merchants',
      columns: ['id'],
      orderBy: 'id ASC',
    );
    expect(merchants.map((merchant) => merchant['id']), [
      'biedronka',
      'receipts',
    ]);
  });

  test('opens legacy database name when new database does not exist', () async {
    DatabaseHelper.configureForTesting(databaseName: null);
    final legacyPath = p.join(dbDirectory.path, DatabaseHelper.legacyDbName);
    final legacyDb = await openDatabase(
      legacyPath,
      version: DatabaseHelper.dbVersion,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE marker(value TEXT NOT NULL)');
        await db.insert('marker', {'value': 'legacy'});
      },
    );
    await legacyDb.close();

    final db = await DatabaseHelper.database;
    final marker = await db.query('marker');

    expect(marker.single['value'], 'legacy');
    expect(
      await databaseFactory.databaseExists(
        p.join(dbDirectory.path, DatabaseHelper.dbName),
      ),
      isFalse,
    );
  });

  test('upgrades v1 legacy categories to current category definitions',
      () async {
    DatabaseHelper.configureForTesting(databaseName: 'migration.db');
    final path = p.join(dbDirectory.path, 'migration.db');
    final oldDb = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories(
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            parent_id TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE category_month_totals(
            category_id TEXT NOT NULL,
            year INTEGER NOT NULL,
            month INTEGER NOT NULL,
            total REAL NOT NULL,
            PRIMARY KEY (category_id, year, month)
          )
        ''');
        await db.execute('''
          CREATE TABLE line_items(
            id TEXT PRIMARY KEY,
            category_id TEXT NOT NULL
          )
        ''');
        await db.insert('categories', {
          'id': 'dairy',
          'name': 'Legacy Dairy',
        });
        await db.insert('category_month_totals', {
          'category_id': 'dairy',
          'year': 2025,
          'month': 8,
          'total': 12.50,
        });
        await db.insert('line_items', {
          'id': 'item-1',
          'category_id': 'dairy',
        });
      },
    );
    await oldDb.close();

    final db = await DatabaseHelper.database;

    final normalizedTotals = await db.query(
      'category_month_totals',
      where: 'category_id = ? AND year = ? AND month = ?',
      whereArgs: [CategoryIds.dairyEggsBakery, 2025, 8],
    );
    expect(normalizedTotals, hasLength(1));
    expect(
      (normalizedTotals.single['total'] as num).toDouble(),
      closeTo(12.50, 0.01),
    );

    final migratedItems = await db.query('line_items');
    expect(migratedItems.single['category_id'], CategoryIds.dairyEggsBakery);

    final legacyCategories = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: ['dairy'],
    );
    expect(legacyCategories, isEmpty);
  });
}
