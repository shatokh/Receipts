import 'package:receipts/domain/models/month_overview.dart';
import 'package:receipts/domain/models/monthly_total.dart';

class MonthViewModel {
  const MonthViewModel({
    required this.normalizedSelectedMonth,
    required this.dropdownMonths,
    required this.replacementSelectedMonth,
    required this.totalAmount,
    required this.receiptsCount,
  });

  final DateTime normalizedSelectedMonth;
  final List<DateTime> dropdownMonths;
  final DateTime? replacementSelectedMonth;
  final double? totalAmount;
  final int receiptsCount;

  factory MonthViewModel.fromData({
    required List<MonthlyTotal>? totals,
    required DateTime selectedMonth,
    required MonthOverview? overview,
  }) {
    final normalizedSelected =
        DateTime(selectedMonth.year, selectedMonth.month);
    final monthlyTotals = totals ?? const <MonthlyTotal>[];
    final monthsWithData = monthlyTotals
        .where((total) => total.total > 0)
        .map((total) => DateTime(total.year, total.month))
        .toList();

    final uniqueMonths = <DateTime>{};
    if (monthsWithData.isEmpty) {
      uniqueMonths.addAll(
        monthlyTotals.map((total) => DateTime(total.year, total.month)),
      );
    } else {
      uniqueMonths.addAll(monthsWithData);
    }
    uniqueMonths.add(normalizedSelected);

    final dropdownMonths = uniqueMonths.toList()
      ..sort((a, b) => a.compareTo(b));

    final replacementSelectedMonth = monthlyTotals.isEmpty ||
            monthsWithData.isEmpty ||
            monthsWithData.any(
              (month) => _isSameMonth(month, normalizedSelected),
            )
        ? null
        : monthsWithData.last;

    return MonthViewModel(
      normalizedSelectedMonth: normalizedSelected,
      dropdownMonths: dropdownMonths,
      replacementSelectedMonth: replacementSelectedMonth,
      totalAmount: overview?.total,
      receiptsCount: overview?.receiptsCount ?? 0,
    );
  }

  static bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
