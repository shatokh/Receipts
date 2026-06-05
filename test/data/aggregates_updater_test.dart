import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/data/aggregates_updater.dart';
import 'package:receipts/data/database.dart';
import 'package:receipts/domain/category_definitions.dart';

import '../helpers/test_environment.dart';

void main() {
  late TestAppHarness harness;

  setUp(() async {
    harness = TestAppHarness();
    await harness.setUp();
    await DatabaseHelper.database;
  });

  tearDown(() async {
    await harness.tearDown();
  });

  test('rebuildAll rebuilds totals and normalizes legacy category ids',
      () async {
    final db = await DatabaseHelper.database;
    await db.insert('categories', {
      'id': 'dairy',
      'name': 'Legacy Dairy',
    });
    await db.insert('receipts', {
      'id': 'receipt-1',
      'merchant_id': 'receipts',
      'purchase_ts': DateTime(2025, 8, 14).millisecondsSinceEpoch,
      'currency': 'PLN',
      'total_gross': 12.50,
      'total_vat': 0.0,
      'source_uri': null,
      'file_hash': 'receipt-1-hash',
    });
    await db.insert('line_items', {
      'id': 'item-1',
      'receipt_id': 'receipt-1',
      'name': 'Milk',
      'quantity': 1.0,
      'unit': 'szt',
      'unit_price': 12.50,
      'discount': 0.0,
      'vat_rate': 0.0,
      'total': 12.50,
      'category_id': 'dairy',
    });

    await const AggregatesUpdater().rebuildAll(db);

    final monthlyRows = await db.query(
      'monthly_totals',
      where: 'year = ? AND month = ?',
      whereArgs: [2025, 8],
    );
    expect(monthlyRows, hasLength(1));
    expect(
      (monthlyRows.single['total'] as num).toDouble(),
      closeTo(12.50, 0.01),
    );

    final normalizedRows = await db.query(
      'category_month_totals',
      where: 'category_id = ? AND year = ? AND month = ?',
      whereArgs: [CategoryIds.dairyEggsBakery, 2025, 8],
    );
    expect(normalizedRows, hasLength(1));
    expect(
      (normalizedRows.single['total'] as num).toDouble(),
      closeTo(12.50, 0.01),
    );

    final legacyRows = await db.query(
      'category_month_totals',
      where: 'category_id = ?',
      whereArgs: ['dairy'],
    );
    expect(legacyRows, isEmpty);
  });
}
