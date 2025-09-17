class ReceiptRow {
  final String id;
  final String merchantId;
  final String merchantName;
  final DateTime purchaseTimestamp;
  final String currency;
  final double totalGross;

  const ReceiptRow({
    required this.id,
    required this.merchantId,
    required this.merchantName,
    required this.purchaseTimestamp,
    required this.currency,
    required this.totalGross,
  });

  factory ReceiptRow.fromMap(Map<String, dynamic> map) => ReceiptRow(
        id: map['id'] as String,
        merchantId: map['merchant_id'] as String,
        merchantName: (map['merchant_name'] as String?)?.isNotEmpty == true
            ? map['merchant_name'] as String
            : 'Biedronka',
        purchaseTimestamp:
            DateTime.fromMillisecondsSinceEpoch(map['purchase_ts'] as int),
        currency: (map['currency'] as String?) ?? 'PLN',
        totalGross: (map['total_gross'] as num).toDouble(),
      );
}
