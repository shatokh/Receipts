import 'package:intl/intl.dart';

import 'package:receipts/domain/models/monthly_total.dart';
import 'package:receipts/domain/models/receipt_row.dart';

class ReceiptsFilterState {
  const ReceiptsFilterState({
    required this.query,
    required this.month,
    required this.minAmount,
    required this.maxAmount,
  });

  final String query;
  final DateTime? month;
  final double minAmount;
  final double maxAmount;

  List<ReceiptRow> apply(List<ReceiptRow> receipts) {
    final normalizedQuery = query.trim().toLowerCase();
    final dateFormat = DateFormat('yyyy-MM-dd');

    return receipts.where((receipt) {
      final matchesQuery = normalizedQuery.isEmpty ||
          receipt.merchantName.toLowerCase().contains(normalizedQuery) ||
          dateFormat.format(receipt.purchaseTimestamp).contains(
                normalizedQuery,
              );

      final matchesMonth = month == null
          ? true
          : receipt.purchaseTimestamp.year == month!.year &&
              receipt.purchaseTimestamp.month == month!.month;

      final total = receipt.totalGross;
      final matchesAmount = total >= minAmount && total <= maxAmount;

      return matchesQuery && matchesMonth && matchesAmount;
    }).toList();
  }

  static List<DateTime> buildFilterMonths(List<MonthlyTotal> totals) {
    final months = <DateTime>{};
    for (final total in totals) {
      if (total.total > 0) {
        months.add(DateTime(total.year, total.month));
      }
    }
    if (months.isEmpty) {
      months.addAll(totals.map((total) => DateTime(total.year, total.month)));
    }
    final list = months.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }
}
