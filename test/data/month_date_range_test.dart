import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/data/month_date_range.dart';
import 'package:receipts/domain/value_objects/receipt_month.dart';

void main() {
  test('forDate normalizes a date inside a month', () {
    final range = MonthDateRange.forDate(DateTime(2026, 6, 15, 12, 30));

    expect(range.start, DateTime(2026, 6));
    expect(range.end, DateTime(2026, 7));
  });

  test('forDate rolls December into January of the next year', () {
    final range = MonthDateRange.forDate(DateTime(2026, 12, 31, 23, 59));

    expect(range.start, DateTime(2026, 12));
    expect(range.end, DateTime(2027, 1));
  });

  test('forDate handles leap-year February boundaries', () {
    final range = MonthDateRange.forDate(DateTime(2024, 2, 29));

    expect(range.start, DateTime(2024, 2));
    expect(range.end, DateTime(2024, 3));
    expect(range.end.difference(range.start).inDays, 29);
  });

  test('forYearMonth creates a half-open month range', () {
    final range = MonthDateRange.forYearMonth(2025, 8);

    expect(range.start, DateTime(2025, 8));
    expect(range.end, DateTime(2025, 9));
    expect(range.startMs, DateTime(2025, 8).millisecondsSinceEpoch);
    expect(range.endMs, DateTime(2025, 9).millisecondsSinceEpoch);
  });

  test('forReceiptMonth uses receipt month boundaries', () {
    final range = MonthDateRange.forReceiptMonth(
      const ReceiptMonth(year: 2025, month: 12),
    );

    expect(range.start, DateTime(2025, 12));
    expect(range.end, DateTime(2026, 1));
  });
}
