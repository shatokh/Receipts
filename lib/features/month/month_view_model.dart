import 'package:receipts/domain/models/month_overview.dart';
import 'package:receipts/domain/models/monthly_total.dart';
import 'package:receipts/domain/value_objects/receipt_month.dart';

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
    final selectedReceiptMonth = ReceiptMonth.fromDate(selectedMonth);
    final normalizedSelected = selectedReceiptMonth.start;
    final monthlyTotals = totals ?? const <MonthlyTotal>[];
    final monthsWithData = monthlyTotals
        .where((total) => total.total > 0)
        .map(ReceiptMonth.fromMonthlyTotal)
        .toList();

    final uniqueMonths = <ReceiptMonth>{};
    if (monthsWithData.isEmpty) {
      uniqueMonths.addAll(
        monthlyTotals.map(ReceiptMonth.fromMonthlyTotal),
      );
    } else {
      uniqueMonths.addAll(monthsWithData);
    }
    uniqueMonths.add(selectedReceiptMonth);

    final dropdownMonths = ReceiptMonth.sortedStarts(uniqueMonths);

    final replacementSelectedMonth = monthlyTotals.isEmpty ||
            monthsWithData.isEmpty ||
            monthsWithData.any(
              (month) => month == selectedReceiptMonth,
            )
        ? null
        : monthsWithData.last.start;

    return MonthViewModel(
      normalizedSelectedMonth: normalizedSelected,
      dropdownMonths: dropdownMonths,
      replacementSelectedMonth: replacementSelectedMonth,
      totalAmount: overview?.total,
      receiptsCount: overview?.receiptsCount ?? 0,
    );
  }
}
