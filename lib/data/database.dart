import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

import 'package:receipts/domain/category_definitions.dart';

class DatabaseHelper {
  static Database? _database;
  static const String dbName = 'receipts.db';
  static const String legacyDbName = 'biedronka_expenses.db';
  static const int dbVersion = 2;
  static String? _databaseNameOverride;

  static void configureForTesting({String? databaseName}) {
    _databaseNameOverride = databaseName;
    if (!kIsWeb && databaseFactoryOrNull == null) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;
    await _initializeDatabaseFactory();
    _database = await _initDB();
    return _database!;
  }

  static Future<void> _initializeDatabaseFactory() async {
    // Initialize FFI database factory for web platforms
    if (kIsWeb) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final name = _databaseNameOverride ?? dbName;
    var path = join(dbPath, name);

    if (!kIsWeb && _databaseNameOverride == null) {
      final factory = databaseFactoryOrNull;
      if (factory != null) {
        final legacyPath = join(dbPath, legacyDbName);
        final hasLegacy = await factory.databaseExists(legacyPath);
        final hasNew = await factory.databaseExists(path);

        if (hasLegacy && !hasNew) {
          path = legacyPath;
        }
      }
    }

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  static Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE merchants(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        nip TEXT,
        address TEXT,
        city TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_id TEXT,
        FOREIGN KEY (parent_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE receipts(
        id TEXT PRIMARY KEY,
        merchant_id TEXT NOT NULL,
        purchase_ts INTEGER NOT NULL,
        currency TEXT DEFAULT 'PLN',
        total_gross REAL NOT NULL,
        total_vat REAL NOT NULL,
        source_uri TEXT,
        file_hash TEXT UNIQUE,
        FOREIGN KEY (merchant_id) REFERENCES merchants (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE line_items(
        id TEXT PRIMARY KEY,
        receipt_id TEXT NOT NULL,
        name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        unit_price REAL NOT NULL,
        discount REAL DEFAULT 0,
        vat_rate REAL NOT NULL,
        total REAL NOT NULL,
        category_id TEXT NOT NULL,
        FOREIGN KEY (receipt_id) REFERENCES receipts (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE monthly_totals(
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        total REAL NOT NULL,
        PRIMARY KEY (year, month)
      )
    ''');

    await db.execute('''
      CREATE TABLE category_month_totals(
        category_id TEXT NOT NULL,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        total REAL NOT NULL,
        PRIMARY KEY (category_id, year, month),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Indexes for performance
    await db.execute(
        'CREATE INDEX idx_receipts_purchase_ts ON receipts(purchase_ts)');
    await db.execute(
        'CREATE INDEX idx_receipts_total_gross ON receipts(total_gross)');
    await db.execute(
        'CREATE INDEX idx_line_items_receipt_id ON line_items(receipt_id)');

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  static Future<void> _upgradeDB(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await _migrateCategoriesToDefinitions(db);
    }
  }

  static Future<void> _migrateCategoriesToDefinitions(Database db) async {
    await db.transaction((txn) async {
      for (final definition in categoryDefinitions) {
        await txn.execute(
          'INSERT OR IGNORE INTO categories (id, name) VALUES (?, ?)',
          [definition.id, definition.label],
        );
        await txn.update(
          'categories',
          {'name': definition.label},
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
              '''.trim(),
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

  static Future<void> _insertDefaultCategories(Database db) async {
    for (final definition in categoryDefinitions) {
      await db.insert('categories', {
        'id': definition.id,
        'name': definition.label,
      });
    }

    // Insert default merchants
    await db.insert('merchants', {
      'id': 'receipts',
      'name': 'Receipts',
      'nip': '0000000000',
      'address': 'ul. Przykładowa 1',
      'city': 'Warszawa',
    });

    await db.insert('merchants', {
      'id': 'biedronka',
      'name': 'Biedronka',
      'nip': '5261040567',
      'address': 'ul. Żółkiewskiego 17/19',
      'city': 'Kraków',
    });
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
