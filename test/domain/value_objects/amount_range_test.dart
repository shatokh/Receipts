import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/domain/value_objects/amount_range.dart';

void main() {
  test('contains values inclusively', () {
    const range = AmountRange(min: 10, max: 20);

    expect(range.contains(9.99), isFalse);
    expect(range.contains(10), isTrue);
    expect(range.contains(15), isTrue);
    expect(range.contains(20), isTrue);
    expect(range.contains(20.01), isFalse);
  });

  test('default receipt filter matches existing slider range', () {
    expect(AmountRange.receiptFilterDefault.min, 0);
    expect(AmountRange.receiptFilterDefault.max, 1000);
  });

  test('supports value equality', () {
    expect(
      const AmountRange(min: 1, max: 2),
      const AmountRange(min: 1, max: 2),
    );
  });
}
