import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/application/receipts/receipts_filter_state.dart';
import 'package:receipts/domain/models/monthly_total.dart';
import 'package:receipts/domain/models/receipt_row.dart';

void main() {
  test('filters receipts by merchant query', () {
    final filter = const ReceiptsFilterState(
      query: 'store',
      month: null,
      minAmount: 0,
      maxAmount: 1000,
    );

    expect(
      filter.apply([
        _receipt(id: '1', merchantName: 'Test Store'),
        _receipt(id: '2', merchantName: 'Other Market'),
      ]).map((receipt) => receipt.id),
      ['1'],
    );
  });

  test('filters receipts by purchase date query', () {
    final filter = const ReceiptsFilterState(
      query: '2025-08-12',
      month: null,
      minAmount: 0,
      maxAmount: 1000,
    );

    expect(
      filter.apply([
        _receipt(id: '1', date: DateTime(2025, 8, 12, 10)),
        _receipt(id: '2', date: DateTime(2025, 8, 13, 10)),
      ]).map((receipt) => receipt.id),
      ['1'],
    );
  });

  test('filters receipts by month', () {
    final filter = ReceiptsFilterState(
      query: '',
      month: DateTime(2025, 8),
      minAmount: 0,
      maxAmount: 1000,
    );

    expect(
      filter.apply([
        _receipt(id: '1', date: DateTime(2025, 8, 1)),
        _receipt(id: '2', date: DateTime(2025, 9, 1)),
      ]).map((receipt) => receipt.id),
      ['1'],
    );
  });

  test('filters receipts by amount range', () {
    final filter = const ReceiptsFilterState(
      query: '',
      month: null,
      minAmount: 10,
      maxAmount: 20,
    );

    expect(
      filter.apply([
        _receipt(id: '1', total: 9.99),
        _receipt(id: '2', total: 10),
        _receipt(id: '3', total: 20),
        _receipt(id: '4', total: 20.01),
      ]).map((receipt) => receipt.id),
      ['2', '3'],
    );
  });

  test('combines query, month, and amount filters', () {
    final filter = ReceiptsFilterState(
      query: 'market',
      month: DateTime(2025, 8),
      minAmount: 10,
      maxAmount: 20,
    );

    expect(
      filter.apply([
        _receipt(
          id: '1',
          merchantName: 'Test Market',
          date: DateTime(2025, 8, 1),
          total: 15,
        ),
        _receipt(
          id: '2',
          merchantName: 'Test Market',
          date: DateTime(2025, 9, 1),
          total: 15,
        ),
        _receipt(
          id: '3',
          merchantName: 'Test Store',
          date: DateTime(2025, 8, 1),
          total: 15,
        ),
        _receipt(
          id: '4',
          merchantName: 'Test Market',
          date: DateTime(2025, 8, 1),
          total: 25,
        ),
      ]).map((receipt) => receipt.id),
      ['1'],
    );
  });

  test('buildFilterMonths prefers months with positive totals descending', () {
    expect(
      ReceiptsFilterState.buildFilterMonths(const [
        MonthlyTotal(year: 2025, month: 7, total: 0),
        MonthlyTotal(year: 2025, month: 8, total: 25),
        MonthlyTotal(year: 2025, month: 9, total: 10),
      ]),
      [DateTime(2025, 9), DateTime(2025, 8)],
    );
  });

  test('buildFilterMonths uses all returned months when totals are zero', () {
    expect(
      ReceiptsFilterState.buildFilterMonths(const [
        MonthlyTotal(year: 2025, month: 7, total: 0),
        MonthlyTotal(year: 2025, month: 8, total: 0),
      ]),
      [DateTime(2025, 8), DateTime(2025, 7)],
    );
  });
}

ReceiptRow _receipt({
  required String id,
  String merchantName = 'Test Store',
  DateTime? date,
  double total = 12.5,
}) {
  return ReceiptRow(
    id: id,
    merchantId: 'merchant-$id',
    merchantName: merchantName,
    purchaseTimestamp: date ?? DateTime(2025, 8, 12),
    currency: 'PLN',
    totalGross: total,
  );
}
