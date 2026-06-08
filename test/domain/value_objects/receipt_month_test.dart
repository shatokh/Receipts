import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/domain/models/monthly_total.dart';
import 'package:receipts/domain/value_objects/receipt_month.dart';

void main() {
  test('fromDate normalizes to year and month only', () {
    final month = ReceiptMonth.fromDate(DateTime(2025, 8, 12, 10, 30));

    expect(month.year, 2025);
    expect(month.month, 8);
    expect(month.start, DateTime(2025, 8));
    expect(month.nextStart, DateTime(2025, 9));
  });

  test('fromMonthlyTotal maps aggregate year and month', () {
    final month = ReceiptMonth.fromMonthlyTotal(
      const MonthlyTotal(year: 2025, month: 7, total: 10),
    );

    expect(month, const ReceiptMonth(year: 2025, month: 7));
  });

  test('compares by year then month', () {
    final months = [
      const ReceiptMonth(year: 2025, month: 8),
      const ReceiptMonth(year: 2024, month: 12),
      const ReceiptMonth(year: 2025, month: 1),
    ]..sort();

    expect(months, [
      const ReceiptMonth(year: 2024, month: 12),
      const ReceiptMonth(year: 2025, month: 1),
      const ReceiptMonth(year: 2025, month: 8),
    ]);
  });

  test('sortedStarts deduplicates and returns ascending DateTime starts', () {
    expect(
      ReceiptMonth.sortedStarts([
        const ReceiptMonth(year: 2025, month: 8),
        const ReceiptMonth(year: 2025, month: 7),
        const ReceiptMonth(year: 2025, month: 8),
      ]),
      [DateTime(2025, 7), DateTime(2025, 8)],
    );
  });

  test('sortedStartsDescending deduplicates and returns descending starts', () {
    expect(
      ReceiptMonth.sortedStartsDescending([
        const ReceiptMonth(year: 2025, month: 8),
        const ReceiptMonth(year: 2025, month: 7),
        const ReceiptMonth(year: 2025, month: 8),
      ]),
      [DateTime(2025, 8), DateTime(2025, 7)],
    );
  });
}
