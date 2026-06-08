import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/domain/models/line_item.dart';
import 'package:receipts/domain/models/merchant.dart';
import 'package:receipts/domain/models/receipt.dart';
import 'package:receipts/domain/models/receipt_details.dart';
import 'package:receipts/features/receipt_details/receipt_details_view_model.dart';

void main() {
  test('maps receipt header and VAT summary values', () {
    final viewModel = ReceiptDetailsViewModel.fromDetails(
      _details(
        items: const [],
      ),
    );

    expect(viewModel.merchantName, 'Test Store');
    expect(viewModel.purchaseTimestampText, '2025-08-12 10:30');
    expect(viewModel.totalGrossText, 'PLN 12.50');
    expect(viewModel.totalVatText, 'PLN 1.25');
    expect(viewModel.hasLineItems, isFalse);
  });

  test('maps regular line item row values', () {
    final viewModel = ReceiptDetailsViewModel.fromDetails(
      _details(
        items: const [
          LineItem(
            id: 'item-1',
            receiptId: 'receipt-1',
            name: 'Test item',
            quantity: 2,
            unit: 'pcs',
            unitPrice: 3.5,
            vatRate: 0.23,
            total: 7,
            categoryId: 'other',
          ),
        ],
      ),
    );

    final item = viewModel.items.single;
    expect(item.name, 'Test item');
    expect(item.quantityPriceText, '2 × PLN 3.50');
    expect(item.vatText, '23%');
    expect(item.totalText, 'PLN 7.00');
    expect(item.isDiscount, isFalse);
  });

  test('maps fractional quantity with two decimal places', () {
    final viewModel = ReceiptDetailsViewModel.fromDetails(
      _details(
        items: const [
          LineItem(
            id: 'item-1',
            receiptId: 'receipt-1',
            name: 'Weighted item',
            quantity: 1.25,
            unit: 'kg',
            unitPrice: 4,
            vatRate: 0.05,
            total: 5,
            categoryId: 'food',
          ),
        ],
      ),
    );

    expect(viewModel.items.single.quantityPriceText, '1.25 × PLN 4.00');
  });

  test('maps discount rows with placeholder quantity and VAT', () {
    final viewModel = ReceiptDetailsViewModel.fromDetails(
      _details(
        items: const [
          LineItem(
            id: 'item-1',
            receiptId: 'receipt-1',
            name: 'Discount',
            quantity: 1,
            unit: 'pcs',
            unitPrice: 2,
            discount: 2,
            vatRate: 0.23,
            total: -2,
            categoryId: 'other',
          ),
        ],
      ),
    );

    final item = viewModel.items.single;
    expect(item.quantityPriceText, '—');
    expect(item.vatText, '—');
    expect(item.totalText, '-PLN 2.00');
    expect(item.isDiscount, isTrue);
  });
}

ReceiptDetails _details({
  required List<LineItem> items,
}) {
  return ReceiptDetails(
    receipt: Receipt(
      id: 'receipt-1',
      merchantId: 'merchant-1',
      purchaseTimestamp: DateTime(2025, 8, 12, 10, 30),
      totalGross: 12.5,
      totalVat: 1.25,
    ),
    merchant: const Merchant(
      id: 'merchant-1',
      name: 'Test Store',
    ),
    items: items,
  );
}
