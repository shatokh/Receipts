import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/data/database.dart';
import 'package:receipts/data/repositories/analytics_repository.dart';
import 'package:receipts/data/repositories/receipt_repository.dart';
import 'package:receipts/domain/category_definitions.dart';

import '../helpers/domain_factories.dart';
import '../helpers/test_environment.dart';

void main() {
  late TestAppHarness harness;
  late ReceiptRepository receiptRepository;
  late AnalyticsRepository analyticsRepository;

  setUp(() async {
    harness = TestAppHarness();
    await harness.setUp();
    receiptRepository = ReceiptRepository(harness.container.read);
    analyticsRepository = AnalyticsRepository(harness.container.read);
    final db = await DatabaseHelper.database;
    await db.insert('categories', {
      'id': 'dairy',
      'name': 'Legacy Dairy',
    });
  });

  tearDown(() async {
    await harness.tearDown();
  });

  test('getMonthOverview returns totals and normalized category breakdowns',
      () async {
    await receiptRepository.insertReceiptWithItems(
      receipt: buildReceipt(
        id: 'receipt-1',
        date: DateTime(2025, 8, 14),
        total: 23.40,
      ),
      items: [
        buildLineItem(
          id: 'item-1',
          receiptId: 'receipt-1',
          total: 23.40,
          categoryId: 'dairy',
        ),
      ],
    );

    final overview = await analyticsRepository.getMonthOverview(
      DateTime(2025, 8, 31),
    );

    expect(overview.month, DateTime(2025, 8));
    expect(overview.total, closeTo(23.40, 0.01));
    expect(overview.receiptsCount, 1);
    expect(overview.averageReceipt, closeTo(23.40, 0.01));
    expect(overview.maxReceipt?.id, 'receipt-1');

    final dairy = overview.topCategories.singleWhere(
      (category) => category.categoryId == CategoryIds.dairyEggsBakery,
    );
    expect(dairy.amount, closeTo(23.40, 0.01));
  });

  test('watchLast12MonthsTotals emits existing month totals in ascending order',
      () async {
    await receiptRepository.insertReceiptWithItems(
      receipt: buildReceipt(
        id: 'receipt-august',
        date: DateTime(2025, 8, 14),
        total: 10,
      ),
      items: [
        buildLineItem(
          id: 'item-august',
          receiptId: 'receipt-august',
          total: 10,
          categoryId: CategoryIds.misc,
        ),
      ],
    );
    await receiptRepository.insertReceiptWithItems(
      receipt: buildReceipt(
        id: 'receipt-september',
        date: DateTime(2025, 9, 1),
        total: 20,
      ),
      items: [
        buildLineItem(
          id: 'item-september',
          receiptId: 'receipt-september',
          total: 20,
          categoryId: CategoryIds.misc,
        ),
      ],
    );

    final totals = await analyticsRepository.watchLast12MonthsTotals().first;

    expect(totals.map((total) => '${total.year}-${total.month}'), [
      '2025-8',
      '2025-9',
    ]);
    expect(totals.map((total) => total.total), [
      closeTo(10, 0.01),
      closeTo(20, 0.01),
    ]);
  });
}
