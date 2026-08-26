import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/data/database.dart';
import 'package:receipts/data/repositories/receipt_repository.dart';
import 'package:receipts/domain/category_definitions.dart';

import '../helpers/domain_factories.dart';
import '../helpers/test_environment.dart';

void main() {
  late TestAppHarness harness;
  late ReceiptRepository repository;

  setUp(() async {
    harness = TestAppHarness();
    await harness.setUp();
    repository = ReceiptRepository(harness.container.read);
    await DatabaseHelper.database;
  });

  tearDown(() async {
    await harness.tearDown();
  });

  test('insertReceiptWithItems updates aggregates and emits update bus',
      () async {
    final update = repository.updates.first.timeout(
      const Duration(seconds: 2),
    );

    await repository.insertReceiptWithItems(
      receipt: buildReceipt(
        id: 'receipt-1',
        date: DateTime(2025, 8, 14),
        total: 23.40,
      ),
      items: [
        buildLineItem(
          id: 'item-1',
          receiptId: 'receipt-1',
          total: 10,
          categoryId: CategoryIds.dairyEggsBakery,
        ),
        buildLineItem(
          id: 'item-2',
          receiptId: 'receipt-1',
          total: 13.40,
          categoryId: CategoryIds.packagedPantry,
        ),
      ],
    );

    await update;

    expect(await _monthlyTotal(2025, 8), closeTo(23.40, 0.01));
    expect(
      await _categoryTotal(CategoryIds.dairyEggsBakery, 2025, 8),
      closeTo(10, 0.01),
    );
    expect(
      await _categoryTotal(CategoryIds.packagedPantry, 2025, 8),
      closeTo(13.40, 0.01),
    );
  });

  test('insertReceiptWithItems rolls back receipt when item insert fails',
      () async {
    await expectLater(
      repository.insertReceiptWithItems(
        receipt: buildReceipt(
          id: 'receipt-rollback',
          date: DateTime(2025, 8, 14),
          total: 20,
        ),
        items: [
          buildLineItem(
            id: 'duplicate-item',
            receiptId: 'receipt-rollback',
            total: 10,
            categoryId: CategoryIds.dairyEggsBakery,
          ),
          buildLineItem(
            id: 'duplicate-item',
            receiptId: 'receipt-rollback',
            total: 10,
            categoryId: CategoryIds.packagedPantry,
          ),
        ],
      ),
      throwsA(anything),
    );

    final db = await DatabaseHelper.database;
    expect(
      await db.query(
        'receipts',
        where: 'id = ?',
        whereArgs: ['receipt-rollback'],
      ),
      isEmpty,
    );
    expect(
      await db.query(
        'line_items',
        where: 'receipt_id = ?',
        whereArgs: ['receipt-rollback'],
      ),
      isEmpty,
    );
    expect(await _monthlyTotal(2025, 8), isNull);
    expect(await _categoryTotal(CategoryIds.dairyEggsBakery, 2025, 8), isNull);
    expect(await _categoryTotal(CategoryIds.packagedPantry, 2025, 8), isNull);
  });

  test('insertReceiptWithItems keeps aggregates isolated by month and category',
      () async {
    await repository.insertReceiptWithItems(
      receipt: buildReceipt(
        id: 'receipt-aug-dairy',
        date: DateTime(2025, 8, 14),
        total: 10,
      ),
      items: [
        buildLineItem(
          id: 'item-aug-dairy',
          receiptId: 'receipt-aug-dairy',
          total: 10,
          categoryId: CategoryIds.dairyEggsBakery,
        ),
      ],
    );
    await repository.insertReceiptWithItems(
      receipt: buildReceipt(
        id: 'receipt-aug-pantry',
        date: DateTime(2025, 8, 20),
        total: 15,
      ),
      items: [
        buildLineItem(
          id: 'item-aug-pantry',
          receiptId: 'receipt-aug-pantry',
          total: 15,
          categoryId: CategoryIds.packagedPantry,
        ),
      ],
    );
    await repository.insertReceiptWithItems(
      receipt: buildReceipt(
        id: 'receipt-sept-dairy',
        date: DateTime(2025, 9, 1),
        total: 7,
      ),
      items: [
        buildLineItem(
          id: 'item-sept-dairy',
          receiptId: 'receipt-sept-dairy',
          total: 7,
          categoryId: CategoryIds.dairyEggsBakery,
        ),
      ],
    );

    expect(await _monthlyTotal(2025, 8), closeTo(25, 0.01));
    expect(await _monthlyTotal(2025, 9), closeTo(7, 0.01));
    expect(
      await _categoryTotal(CategoryIds.dairyEggsBakery, 2025, 8),
      closeTo(10, 0.01),
    );
    expect(
      await _categoryTotal(CategoryIds.packagedPantry, 2025, 8),
      closeTo(15, 0.01),
    );
    expect(
      await _categoryTotal(CategoryIds.dairyEggsBakery, 2025, 9),
      closeTo(7, 0.01),
    );
    expect(await _categoryTotal(CategoryIds.packagedPantry, 2025, 9), isNull);
  });

  test('updateReceipt recalculates old and new months', () async {
    await repository.insertReceiptWithItems(
      receipt: buildReceipt(
        id: 'receipt-1',
        date: DateTime(2025, 8, 14),
        total: 10,
      ),
      items: [
        buildLineItem(
          id: 'item-1',
          receiptId: 'receipt-1',
          total: 10,
          categoryId: CategoryIds.dairyEggsBakery,
        ),
      ],
    );

    final update = repository.updates.first.timeout(
      const Duration(seconds: 2),
    );

    await repository.updateReceipt(
      buildReceipt(
        id: 'receipt-1',
        date: DateTime(2025, 9, 1),
        total: 10,
      ),
    );

    await update;

    expect(await _monthlyTotal(2025, 8), closeTo(0, 0.01));
    expect(await _categoryTotal(CategoryIds.dairyEggsBakery, 2025, 8), isNull);
    expect(await _monthlyTotal(2025, 9), closeTo(10, 0.01));
    expect(
      await _categoryTotal(CategoryIds.dairyEggsBakery, 2025, 9),
      closeTo(10, 0.01),
    );
  });

  test('deleteReceipt removes receipt items and clears aggregates', () async {
    await repository.insertReceiptWithItems(
      receipt: buildReceipt(
        id: 'receipt-1',
        date: DateTime(2025, 8, 14),
        total: 10,
      ),
      items: [
        buildLineItem(
          id: 'item-1',
          receiptId: 'receipt-1',
          total: 10,
          categoryId: CategoryIds.dairyEggsBakery,
        ),
      ],
    );

    final update = repository.updates.first.timeout(
      const Duration(seconds: 2),
    );

    await repository.deleteReceipt('receipt-1');

    await update;

    final db = await DatabaseHelper.database;
    expect(await db.query('receipts'), isEmpty);
    expect(await db.query('line_items'), isEmpty);
    expect(await _monthlyTotal(2025, 8), closeTo(0, 0.01));
    expect(await _categoryTotal(CategoryIds.dairyEggsBakery, 2025, 8), isNull);
  });

  test('deleteReceipt preserves aggregates for remaining receipts in the month',
      () async {
    await repository.insertReceiptWithItems(
      receipt: buildReceipt(
        id: 'receipt-to-delete',
        date: DateTime(2025, 8, 14),
        total: 10,
      ),
      items: [
        buildLineItem(
          id: 'item-to-delete',
          receiptId: 'receipt-to-delete',
          total: 10,
          categoryId: CategoryIds.dairyEggsBakery,
        ),
      ],
    );
    await repository.insertReceiptWithItems(
      receipt: buildReceipt(
        id: 'receipt-to-keep',
        date: DateTime(2025, 8, 15),
        total: 15,
      ),
      items: [
        buildLineItem(
          id: 'item-to-keep',
          receiptId: 'receipt-to-keep',
          total: 15,
          categoryId: CategoryIds.dairyEggsBakery,
        ),
      ],
    );

    await repository.deleteReceipt('receipt-to-delete');

    expect(await repository.getReceipt('receipt-to-delete'), isNull);
    expect(await repository.getReceipt('receipt-to-keep'), isNotNull);
    expect(await _monthlyTotal(2025, 8), closeTo(15, 0.01));
    expect(
      await _categoryTotal(CategoryIds.dairyEggsBakery, 2025, 8),
      closeTo(15, 0.01),
    );
  });
}

Future<double?> _monthlyTotal(int year, int month) async {
  final db = await DatabaseHelper.database;
  final rows = await db.query(
    'monthly_totals',
    columns: ['total'],
    where: 'year = ? AND month = ?',
    whereArgs: [year, month],
    limit: 1,
  );
  if (rows.isEmpty) {
    return null;
  }
  return (rows.first['total'] as num).toDouble();
}

Future<double?> _categoryTotal(String categoryId, int year, int month) async {
  final db = await DatabaseHelper.database;
  final rows = await db.query(
    'category_month_totals',
    columns: ['total'],
    where: 'category_id = ? AND year = ? AND month = ?',
    whereArgs: [categoryId, year, month],
    limit: 1,
  );
  if (rows.isEmpty) {
    return null;
  }
  return (rows.first['total'] as num).toDouble();
}
