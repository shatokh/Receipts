class MonthlyTotal {
  final int year;
  final int month;
  final double total;

  const MonthlyTotal({
    required this.year,
    required this.month,
    required this.total,
  });

  Map<String, dynamic> toMap() => {
    'year': year,
    'month': month,
    'total': total,
  };

  factory MonthlyTotal.fromMap(Map<String, dynamic> map) => MonthlyTotal(
    year: map['year'],
    month: map['month'],
    total: map['total'],
  );
}

class CategoryMonthTotal {
  final String categoryId;
  final int year;
  final int month;
  final double total;

  const CategoryMonthTotal({
    required this.categoryId,
    required this.year,
    required this.month,
    required this.total,
  });

  Map<String, dynamic> toMap() => {
    'category_id': categoryId,
    'year': year,
    'month': month,
    'total': total,
  };

  factory CategoryMonthTotal.fromMap(Map<String, dynamic> map) => CategoryMonthTotal(
    categoryId: map['category_id'],
    year: map['year'],
    month: map['month'],
    total: map['total'],
  );
}