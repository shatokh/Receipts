import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:biedronka_expenses/data/database.dart';
import 'package:biedronka_expenses/data/database_update_bus.dart';
import 'package:biedronka_expenses/data/database_update_bus_provider.dart';

bool _bootstrapped = false;

/// Ensures Flutter bindings and the sqflite FFI factory are ready for tests.
Future<void> bootstrapTestEnvironment() async {
  if (_bootstrapped) return;
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  _bootstrapped = true;
}

/// Provides a fully isolated Riverpod container and fresh database per test.
class TestAppHarness {
  late final Directory _dbDirectory;
  late final ProviderContainer container;

  Future<void> setUp({List<Override> overrides = const []}) async {
    await bootstrapTestEnvironment();
    _dbDirectory = await Directory.systemTemp.createTemp('reseipts_test_db_');
    databaseFactoryFfi.setDatabasesPath(_dbDirectory.path);

    await DatabaseHelper.close();

    container = ProviderContainer(
      overrides: [
        databaseUpdateBusProvider.overrideWithValue(DatabaseUpdateBus()),
        ...overrides,
      ],
    );
  }

  Future<void> tearDown() async {
    await DatabaseHelper.close();
    container.dispose();
    if (await _dbDirectory.exists()) {
      await _dbDirectory.delete(recursive: true);
    }
  }
}

/// Convenience helper for tests that only need a container.
Future<ProviderContainer> createTestContainer(
    {List<Override> overrides = const []}) async {
  final harness = TestAppHarness();
  await harness.setUp(overrides: overrides);
  addTearDown(harness.tearDown);
  return harness.container;
}
