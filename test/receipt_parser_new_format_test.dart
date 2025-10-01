import 'dart:io';

import 'package:biedronka_expenses/domain/parsing/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses modern Biedronka receipt layout', () async {
    final parser = ReceiptParser();
    final text = await File('assets/sample_receipt_modern.txt').readAsString();

    final receipt = parser.parse(text);

    expect(receipt.merchantId, 'biedronka');
    expect(receipt.purchaseTimestamp, DateTime(2025, 9, 6, 14, 33));
    expect(receipt.totalGross, closeTo(23.26, 0.01));
    expect(receipt.items.length, 4);

    final milk =
        receipt.items.firstWhere((item) => item.name.startsWith('Mleko'));
    expect(milk.quantity, closeTo(1, 0.001));
    expect(milk.unit, 'szt');
    expect(milk.unitPrice, closeTo(5.28, 0.01));

    final cheese = receipt.items
        .firstWhere((item) => item.name.startsWith('Ser żółty'));
    expect(cheese.unit, 'kg');
    expect(cheese.quantity, closeTo(0.3, 0.001));
    expect(cheese.total, closeTo(9.90, 0.01));

    final discount = receipt.items
        .firstWhere((item) => item.name.toLowerCase().contains('rabat'));
    expect(discount.total, closeTo(-1.50, 0.01));
  });
}
