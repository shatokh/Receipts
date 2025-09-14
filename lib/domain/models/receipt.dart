class Receipt {
  final String id;
  final String merchantId;
  final DateTime purchaseTimestamp;
  final String currency;
  final double totalGross;
  final double totalVat;
  final String? sourceUri;
  final String? fileHash;

  const Receipt({
    required this.id,
    required this.merchantId,
    required this.purchaseTimestamp,
    this.currency = 'PLN',
    required this.totalGross,
    required this.totalVat,
    this.sourceUri,
    this.fileHash,
  });

  Receipt copyWith({
    String? id,
    String? merchantId,
    DateTime? purchaseTimestamp,
    String? currency,
    double? totalGross,
    double? totalVat,
    String? sourceUri,
    String? fileHash,
  }) => Receipt(
    id: id ?? this.id,
    merchantId: merchantId ?? this.merchantId,
    purchaseTimestamp: purchaseTimestamp ?? this.purchaseTimestamp,
    currency: currency ?? this.currency,
    totalGross: totalGross ?? this.totalGross,
    totalVat: totalVat ?? this.totalVat,
    sourceUri: sourceUri ?? this.sourceUri,
    fileHash: fileHash ?? this.fileHash,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'merchant_id': merchantId,
    'purchase_ts': purchaseTimestamp.millisecondsSinceEpoch,
    'currency': currency,
    'total_gross': totalGross,
    'total_vat': totalVat,
    'source_uri': sourceUri,
    'file_hash': fileHash,
  };

  factory Receipt.fromMap(Map<String, dynamic> map) => Receipt(
    id: map['id'],
    merchantId: map['merchant_id'],
    purchaseTimestamp: DateTime.fromMillisecondsSinceEpoch(map['purchase_ts']),
    currency: map['currency'] ?? 'PLN',
    totalGross: map['total_gross'],
    totalVat: map['total_vat'],
    sourceUri: map['source_uri'],
    fileHash: map['file_hash'],
  );
}