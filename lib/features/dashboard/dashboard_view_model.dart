import 'package:receipts/domain/models/monthly_total.dart';
import 'package:receipts/domain/value_objects/receipt_month.dart';

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
    final selectedReceiptMonth = ReceiptMonth.fromDate(selectedMonth);
    final normalizedSelected = selectedReceiptMonth.start;
    final monthsWithData = totals
        .where((total) => total.total > 0)
        .map(ReceiptMonth.fromMonthlyTotal)
        .toList();

    final uniqueMonths = <ReceiptMonth>{};
    if (monthsWithData.isEmpty) {
      uniqueMonths.addAll(totals.map(ReceiptMonth.fromMonthlyTotal));
    } else {
      uniqueMonths.addAll(monthsWithData);
    }
    uniqueMonths.add(selectedReceiptMonth);

    final dropdownMonths = ReceiptMonth.sortedStarts(uniqueMonths);

    final replacementSelectedMonth = monthsWithData.isEmpty ||
            monthsWithData.any(
              (month) => month == selectedReceiptMonth,
            )
        ? null
        : monthsWithData.last.start;

    return DashboardViewModel(
      hasMonthlyTotals: totals.isNotEmpty,
      normalizedSelectedMonth: normalizedSelected,
      dropdownMonths: dropdownMonths,
      replacementSelectedMonth: replacementSelectedMonth,
    );
  }
}
