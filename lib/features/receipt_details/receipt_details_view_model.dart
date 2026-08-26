import 'package:intl/intl.dart';

import 'package:receipts/core/formatting/app_formatters.dart';
import 'package:receipts/domain/models/line_item.dart';
import 'package:receipts/domain/models/receipt_details.dart';

class ReceiptDetailsViewModel {
  const ReceiptDetailsViewModel({
    required this.merchantName,
    required this.purchaseTimestampText,
    required this.totalGrossText,
    required this.totalVatText,
    required this.items,
  });

  final String merchantName;
  final String purchaseTimestampText;
  final String totalGrossText;
  final String totalVatText;
  final List<ReceiptLineItemViewModel> items;

  bool get hasLineItems => items.isNotEmpty;

  factory ReceiptDetailsViewModel.fromDetails(
    ReceiptDetails details, {
    DateFormat? dateFormat,
    NumberFormat? currencyFormat,
  }) {
    final resolvedDateFormat = dateFormat ?? AppFormatters.receiptDateTime();
    final resolvedCurrencyFormat =
        currencyFormat ?? AppFormatters.receiptCurrency();

    return ReceiptDetailsViewModel(
      merchantName: details.merchantName,
      purchaseTimestampText: resolvedDateFormat.format(
        details.receipt.purchaseTimestamp,
      ),
      totalGrossText: resolvedCurrencyFormat.format(details.totalGross),
      totalVatText: resolvedCurrencyFormat.format(details.totalVat),
      items: details.items
          .map(
            (item) => ReceiptLineItemViewModel.fromLineItem(
              item,
              currencyFormat: resolvedCurrencyFormat,
            ),
          )
          .toList(),
    );
  }
}

class ReceiptLineItemViewModel {
  const ReceiptLineItemViewModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.quantityPriceText,
    required this.vatText,
    required this.totalText,
    required this.isDiscount,
  });

  final String id;
  final String categoryId;
  final String name;
  final String quantityPriceText;
  final String vatText;
  final String totalText;
  final bool isDiscount;

  factory ReceiptLineItemViewModel.fromLineItem(
    LineItem item, {
    required NumberFormat currencyFormat,
  }) {
    final isDiscount = item.discount > 0 || item.total < 0;
    return ReceiptLineItemViewModel(
      id: item.id,
      categoryId: item.categoryId,
      name: item.name,
      quantityPriceText: isDiscount
          ? '—'
          : '${_formatQuantity(item.quantity)} × ${currencyFormat.format(item.unitPrice)}',
      vatText: isDiscount ? '—' : '${(item.vatRate * 100).toStringAsFixed(0)}%',
      totalText: currencyFormat.format(item.total),
      isDiscount: isDiscount,
    );
  }

  static String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toStringAsFixed(0);
    }
    return quantity.toStringAsFixed(2);
  }
}
