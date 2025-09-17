import 'package:biedronka_expenses/domain/models/receipt_row.dart';

class MonthOverview {
  final DateTime month;
  final double total;
  final int receiptsCount;
  final double averageReceipt;
  final ReceiptRow? maxReceipt;
  final List<CategoryBreakdown> topCategories;

  const MonthOverview({
    required this.month,
    required this.total,
    required this.receiptsCount,
    required this.averageReceipt,
    required this.maxReceipt,
    required this.topCategories,
  });

  double get maxCategoryAmount => topCategories.isEmpty
      ? 0
      : topCategories
          .map((category) => category.amount)
          .reduce((value, element) => value > element ? value : element);

  double get topCategoriesTotal => topCategories.fold(0, (sum, item) => sum + item.amount);
}

class CategoryBreakdown {
  final String categoryId;
  final String categoryName;
  final double amount;

  const CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
  });
}
