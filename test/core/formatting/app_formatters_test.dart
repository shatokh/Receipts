import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/core/formatting/app_formatters.dart';

void main() {
  group('AppFormatters', () {
    test('formats receipt currency with existing PLN output', () {
      final formatter = AppFormatters.receiptCurrency();

      expect(formatter.format(1234.5), 'PLN 1,234.50');
      expect(formatter.format(-7.2), '-PLN 7.20');
    });

    test('formats receipt timestamp with existing pattern', () {
      final formatter = AppFormatters.receiptDateTime();

      expect(
        formatter.format(DateTime(2026, 6, 8, 9, 5)),
        '2026-06-08 09:05',
      );
    });

    test('formats receipt search date with existing pattern', () {
      final formatter = AppFormatters.receiptSearchDate();

      expect(formatter.format(DateTime(2026, 6, 8, 9, 5)), '2026-06-08');
    });
  });
}
