import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/domain/category_definitions.dart';
import 'package:receipts/domain/parsing/receipt_parser.dart';

void main() {
  test('synthetic receipt B preserves date and representative categories', () {
    const text = '''
TESTOWY KOSZYK
PARAGON TESTOWY
18.11.2042 14:37
CHLEB TESTOWY       A 1 szt x 4,20  4,20
JABŁKA PRÓBNE       A 1 kg  x 6,90  6,90
MAKARON DEMO        A 1 szt x 2,70  2,70
KAWA WZÓR           A 1 szt x 12,90 12,90
PAPIER DEMO         A 1 szt x 8,20  8,20
SUMA VAT 21,73
SUMA PLN 104,60
''';

    final receipt = ReceiptParser().parse(text);

    expect(receipt.purchaseTimestamp, DateTime(2042, 11, 18, 14, 37));
    expect(receipt.items, hasLength(5));
    expect(
      receipt.items.map((item) => item.categoryId),
      [
        CategoryIds.dairyEggsBakery,
        CategoryIds.freshProduce,
        CategoryIds.packagedPantry,
        CategoryIds.drinksSnacks,
        CategoryIds.householdGoods,
      ],
    );
  });
}
