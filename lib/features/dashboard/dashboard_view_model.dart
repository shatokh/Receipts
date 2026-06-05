import 'package:receipts/domain/models/monthly_total.dart';

class DashboardViewModel {
  const DashboardViewModel({
    required this.hasMonthlyTotals,
    required this.normalizedSelectedMonth,
    required this.dropdownMonths,
    required this.replacementSelectedMonth,
  });

  final bool hasMonthlyTotals;
  final DateTime normalizedSelectedMonth;
  final List<DateTime> dropdownMonths;
  final DateTime? replacementSelectedMonth;

  factory DashboardViewModel.fromMonthlyTotals({
    required List<MonthlyTotal> totals,
    required DateTime selectedMonth,
  }) {
    final normalizedSelected =
        DateTime(selectedMonth.year, selectedMonth.month);
    final monthsWithData = totals
        .where((total) => total.total > 0)
        .map((total) => DateTime(total.year, total.month))
        .toList();

    final uniqueMonths = <DateTime>{};
    if (monthsWithData.isEmpty) {
      uniqueMonths
          .addAll(totals.map((total) => DateTime(total.year, total.month)));
    } else {
      uniqueMonths.addAll(monthsWithData);
    }
    uniqueMonths.add(normalizedSelected);

    final dropdownMonths = uniqueMonths.toList()
      ..sort((a, b) => a.compareTo(b));

    final replacementSelectedMonth = monthsWithData.isEmpty ||
            monthsWithData.any(
              (month) => _isSameMonth(month, normalizedSelected),
            )
        ? null
        : monthsWithData.last;

    return DashboardViewModel(
      hasMonthlyTotals: totals.isNotEmpty,
      normalizedSelectedMonth: normalizedSelected,
      dropdownMonths: dropdownMonths,
      replacementSelectedMonth: replacementSelectedMonth,
    );
  }

  static bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
