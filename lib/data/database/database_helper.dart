import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'database_migrations.dart';
import 'database_schema.dart';

class DatabaseHelper {
  static Database? _database;
  static const String dbName = 'receipts.db';
  static const String legacyDbName = 'biedronka_expenses.db';
  static const int dbVersion = 2;
  static String? _databaseNameOverride;

  /// Configures an isolated database name for a test run.
  ///
  /// Host-side tests use sqflite FFI by default. Device integration tests must
  /// keep the platform sqflite implementation because FFI is not available on
  /// Android or iOS.
  static void configureForTesting({
    String? databaseName,
    bool useFfi = true,
  }) {
    _databaseNameOverride = databaseName;
    if (useFfi && !kIsWeb) {
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
      final factory = databaseFactory;
      final legacyPath = join(dbPath, legacyDbName);
      final hasLegacy = await factory.databaseExists(legacyPath);
      final hasNew = await factory.databaseExists(path);

      if (hasLegacy && !hasNew) {
        path = legacyPath;
      }
    }

    return openDatabase(
      path,
      version: dbVersion,
      onCreate: createDatabaseSchema,
      onUpgrade: upgradeDatabase,
    );
  }

  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
