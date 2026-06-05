import 'package:sqflite/sqflite.dart';

import 'package:receipts/domain/category_definitions.dart';

Future<void> insertDefaultSeedData(DatabaseExecutor db) async {
  for (final definition in categoryDefinitions) {
    await db.insert('categories', {
      'id': definition.id,
      'name': definition.fallbackLabel,
    });
  }

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
