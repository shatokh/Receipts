import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static Database? _database;
  static const String dbName = 'receipts.db';
  static const int dbVersion = 1;
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
    final path = join(dbPath, name);

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _createDB,
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

  static Future<void> _insertDefaultCategories(Database db) async {
    final categories = [
      {'id': 'produce', 'name': 'Produce'},
      {'id': 'meat', 'name': 'Meat'},
      {'id': 'dairy', 'name': 'Dairy'},
      {'id': 'household', 'name': 'Household'},
      {'id': 'bakery', 'name': 'Bakery'},
      {'id': 'other', 'name': 'Other'},
    ];

    for (final category in categories) {
      await db.insert('categories', category);
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
