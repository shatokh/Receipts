import 'package:receipts/domain/models/line_item.dart';
import 'package:receipts/domain/models/receipt.dart';

Receipt buildReceipt({
  required String id,
  required DateTime date,
  required double total,
  String merchantId = 'receipts',
  double totalVat = 0,
  String? fileHash,
}) {
  return Receipt(
    id: id,
    merchantId: merchantId,
    purchaseTimestamp: date,
    totalGross: total,
    totalVat: totalVat,
    fileHash: fileHash ?? '$id-hash',
  );
}

LineItem buildLineItem({
  required String id,
  required String receiptId,
  required double total,
  required String categoryId,
  String? name,
  double quantity = 1,
  String unit = 'szt',
  double vatRate = 0,
}) {
  return LineItem(
    id: id,
    receiptId: receiptId,
    name: name ?? id,
    quantity: quantity,
    unit: unit,
    unitPrice: total,
    vatRate: vatRate,
    total: total,
    categoryId: categoryId,
  );
}
