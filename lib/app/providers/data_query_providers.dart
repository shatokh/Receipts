import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receipts/app/providers/repository_providers.dart';
import 'package:receipts/domain/models/dashboard_kpis.dart';
import 'package:receipts/domain/models/month_overview.dart';
import 'package:receipts/domain/models/monthly_total.dart';
import 'package:receipts/domain/models/receipt_details.dart';
import 'package:receipts/domain/models/receipt_row.dart';

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime(2025, 8, 1);
});

final monthlyTotalsProvider =
    StreamProvider.autoDispose<List<MonthlyTotal>>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.watchLast12MonthsTotals();
});

final dashboardKpisProvider =
    FutureProvider.autoDispose<DashboardKpis>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final sub = repo.updates.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return repo.getLast30DaysKpi();
});

final monthOverviewProvider = FutureProvider.autoDispose
    .family<MonthOverview, DateTime>((ref, month) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final sub = repo.updates.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return repo.getMonthOverview(month);
});

final receiptsByMonthProvider =
    StreamProvider.autoDispose.family<List<ReceiptRow>, DateTime>((ref, month) {
  final repo = ref.watch(receiptRepositoryProvider);
  return repo.watchReceiptsByMonth(month);
});

final receiptDetailsProvider = FutureProvider.autoDispose
    .family<ReceiptDetails, String>((ref, receiptId) async {
  final repo = ref.watch(receiptRepositoryProvider);
  final sub = repo.updates.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return repo.getReceiptDetails(receiptId);
});
