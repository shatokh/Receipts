class LineItem {
  final String id;
  final String receiptId;
  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double discount;
  final double vatRate;
  final double total;
  final String categoryId;

  const LineItem({
    required this.id,
    required this.receiptId,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.discount = 0.0,
    required this.vatRate,
    required this.total,
    required this.categoryId,
  });

  LineItem copyWith({
    String? id,
    String? receiptId,
    String? name,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? discount,
    double? vatRate,
    double? total,
    String? categoryId,
  }) => LineItem(
    id: id ?? this.id,
    receiptId: receiptId ?? this.receiptId,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    unitPrice: unitPrice ?? this.unitPrice,
    discount: discount ?? this.discount,
    vatRate: vatRate ?? this.vatRate,
    total: total ?? this.total,
    categoryId: categoryId ?? this.categoryId,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'receipt_id': receiptId,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'unit_price': unitPrice,
    'discount': discount,
    'vat_rate': vatRate,
    'total': total,
    'category_id': categoryId,
  };

  factory LineItem.fromMap(Map<String, dynamic> map) => LineItem(
    id: map['id'],
    receiptId: map['receipt_id'],
    name: map['name'],
    quantity: map['quantity'],
    unit: map['unit'],
    unitPrice: map['unit_price'],
    discount: map['discount'] ?? 0.0,
    vatRate: map['vat_rate'],
    total: map['total'],
    categoryId: map['category_id'],
  );
}