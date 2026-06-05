import 'package:sqflite/sqflite.dart';

import 'seed_data.dart';

Future<void> createDatabaseSchema(Database db, int version) async {
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

  await db.execute(
    'CREATE INDEX idx_receipts_purchase_ts ON receipts(purchase_ts)',
  );
  await db.execute(
    'CREATE INDEX idx_receipts_total_gross ON receipts(total_gross)',
  );
  await db.execute(
    'CREATE INDEX idx_line_items_receipt_id ON line_items(receipt_id)',
  );

  await insertDefaultSeedData(db);
}
