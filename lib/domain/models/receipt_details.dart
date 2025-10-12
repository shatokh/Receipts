import 'package:receipts/domain/models/line_item.dart';
import 'package:receipts/domain/models/merchant.dart';
import 'package:receipts/domain/models/receipt.dart';

class ReceiptDetails {
  final Receipt receipt;
  final Merchant? merchant;
  final List<LineItem> items;

  const ReceiptDetails({
    required this.receipt,
    required this.merchant,
    required this.items,
  });

  String get merchantName => merchant?.name ?? 'Receipts';

  double get totalVat => receipt.totalVat;

  double get totalGross => receipt.totalGross;

  double get totalDiscounts => items
      .where((item) => item.discount > 0)
      .fold(0, (sum, item) => sum + item.discount);
}
