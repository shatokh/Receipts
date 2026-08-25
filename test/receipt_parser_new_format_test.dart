import 'dart:convert';
import 'dart:io';

import 'package:receipts/domain/parsing/receipt_parser.dart';
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

    final cheese =
        receipt.items.firstWhere((item) => item.name.startsWith('Ser żółty'));
    expect(cheese.unit, 'kg');
    expect(cheese.quantity, closeTo(0.3, 0.001));
    expect(cheese.total, closeTo(9.90, 0.01));

    final discount = receipt.items
        .firstWhere((item) => item.name.toLowerCase().contains('rabat'));
    expect(discount.total, closeTo(-1.50, 0.01));
  });

  test('detects Jeronimo header even when broken across lines', () async {
    final parser = ReceiptParser();
    final original =
        await File('assets/sample_receipt_modern.txt').readAsString();
    final modified = original.replaceFirst(
      'Jeronimo Martins Polska S.A.',
      'Jeronimo\nMartins\nPolska S.A.',
    );

    final receipt = parser.parse(modified);

    expect(receipt.merchantId, 'biedronka');
    expect(receipt.items, isNotEmpty);
  });

  test('accepts e-receipt header as supported source', () async {
    final parser = ReceiptParser();
    final original = await File('assets/sample_receipt.txt').readAsString();
    final eReceipt = original.replaceFirst('Paragon fiskalny', 'E-Receipt');

    final receipt = parser.parse(eReceipt);

    expect(receipt.merchantId, 'biedronka');
    expect(receipt.items, isNotEmpty);
  });

  test('parses OCR text with ISO-like purchase date', () {
    final parser = ReceiptParser();
    const text = '''
BIEDRONKA CODZIENNIE NISKIE CENY
JERONIMO MARTINS POLSKA S.A.
NIP 7791011327
Paragon fiskalny
2025-09-27 12:34:56
SUMA PLN 42,10
''';

    final receipt = parser.parse(text);

    expect(receipt.merchantId, 'biedronka');
    expect(receipt.purchaseTimestamp, DateTime(2025, 9, 27, 12, 34));
    expect(receipt.totalGross, closeTo(42.10, 0.01));
  });

  test('parses OCR text when date separators are dashes', () {
    final parser = ReceiptParser();
    const text = '''
BIEDRONKA CODZIENNIE NISKIE CENY
JERONIMO MARTINS POLSKA S.A.
Paragon fiskalny
27-09-2025 12:34
SUMA PLN 42,10
''';

    final receipt = parser.parse(text);

    expect(receipt.purchaseTimestamp, DateTime(2025, 9, 27, 12, 34));
    expect(receipt.totalGross, closeTo(42.10, 0.01));
  });

  test('parses JSON receipt export', () async {
    final parser = ReceiptParser();
    final text = await File('assets/sample_receipt.json').readAsString();

    final receipt = parser.parse(text);

    expect(
      receipt.purchaseTimestamp,
      DateTime.parse('2025-10-07T07:44:25.000Z').toLocal(),
    );
    expect(receipt.totalGross, closeTo(73.27, 0.01));
    expect(receipt.totalVat, closeTo(3.49, 0.01));
    expect(receipt.items.length, 6);

    final banan =
        receipt.items.firstWhere((item) => item.name.startsWith('Banan Luz'));
    expect(banan.quantity, closeTo(0.79, 0.001));
    expect(banan.unit, 'kg');

    final discount =
        receipt.items.firstWhere((item) => item.name.toLowerCase() == 'rabat');
    expect(discount.total, closeTo(-1.20, 0.01));
  });

  test('parses compact JPK data when legacy JSON sections are incomplete',
      () async {
    final parser = ReceiptParser();
    final text = await File('assets/2510079156114553 (2).json').readAsString();
    final payload = jsonDecode(text) as Map<String, dynamic>;

    final receipt = parser.parse(jsonEncode({
      'protoVersion': payload['protoVersion'],
      'data': payload['data'],
    }));

    expect(receipt.merchantId, 'biedronka');
    expect(
      receipt.purchaseTimestamp,
      DateTime.parse('2025-10-07T07:44:25.000Z').toLocal(),
    );
    expect(receipt.totalGross, closeTo(73.27, 0.01));
    expect(receipt.totalVat, closeTo(3.49, 0.01));
    expect(receipt.items, isNotEmpty);

    expect(
      receipt.items
          .where((item) => item.unit == 'kg')
          .any((item) => (item.quantity - 0.79).abs() < 0.001),
      isTrue,
    );

    expect(
      receipt.items.any((item) => (item.total + 1.20).abs() < 0.01),
      isTrue,
    );
  });

  test('rejects unsupported text without false-positive import', () {
    final parser = ReceiptParser();

    expect(
      () => parser.parse('Shopping note without fiscal markers'),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects supported text when purchase date is missing', () {
    final parser = ReceiptParser();
    const text = '''
BIEDRONKA CODZIENNIE NISKIE CENY
JERONIMO MARTINS POLSKA S.A.
Paragon fiskalny
SUMA PLN 42,10
''';

    expect(
      () => parser.parse(text),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Missing purchase date',
        ),
      ),
    );
  });

  test('rejects supported text when total is missing', () {
    final parser = ReceiptParser();
    const text = '''
BIEDRONKA CODZIENNIE NISKIE CENY
JERONIMO MARTINS POLSKA S.A.
Paragon fiskalny
27.09.2025 12:34
''';

    expect(
      () => parser.parse(text),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'Missing total amount',
        ),
      ),
    );
  });

  test('rejects malformed JSON payload', () {
    final parser = ReceiptParser();

    expect(
      () => parser.parse('{"header":'),
      throwsA(isA<FormatException>()),
    );
  });
}
