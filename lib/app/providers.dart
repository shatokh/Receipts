import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:biedronka_expenses/data/repositories/analytics_repository.dart';
import 'package:biedronka_expenses/data/repositories/category_repository.dart';
import 'package:biedronka_expenses/data/repositories/receipt_repository.dart';
import 'package:biedronka_expenses/data/repositories/settings_repository.dart';
import 'package:biedronka_expenses/domain/models/dashboard_kpis.dart';
import 'package:biedronka_expenses/domain/models/month_overview.dart';
import 'package:biedronka_expenses/domain/models/monthly_total.dart';
import 'package:biedronka_expenses/domain/models/receipt_details.dart';
import 'package:biedronka_expenses/domain/models/receipt_row.dart';
import 'package:biedronka_expenses/domain/services/receipt_parser.dart';
import 'package:biedronka_expenses/platform/pdf_text_extractor/android_pdf_text_extractor.dart';

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  final repository = ReceiptRepository(ref.read);
  return repository;
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final repository = AnalyticsRepository(ref.read);
  return repository;
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('SettingsRepository must be provided at runtime');
});

final pdfTextExtractorProvider = Provider((ref) {
  return AndroidPdfTextExtractor();
});

final receiptParserProvider = Provider<ReceiptParser>((ref) {
  return ReceiptParser(ref.watch(categoryRepositoryProvider));
});

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime(2025, 8, 1);
});

final monthlyTotalsProvider = StreamProvider.autoDispose<List<MonthlyTotal>>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.watchLast12MonthsTotals();
});

final dashboardKpisProvider = FutureProvider.autoDispose<DashboardKpis>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final sub = repo.updates.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return repo.getLast30DaysKpi();
});

final monthOverviewProvider = FutureProvider.autoDispose.family<MonthOverview, DateTime>((ref, month) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final sub = repo.updates.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return repo.getMonthOverview(month);
});

final receiptsByMonthProvider = StreamProvider.autoDispose.family<List<ReceiptRow>, DateTime>((ref, month) {
  final repo = ref.watch(receiptRepositoryProvider);
  return repo.watchReceiptsByMonth(month);
});

final receiptDetailsProvider = FutureProvider.autoDispose.family<ReceiptDetails, String>((ref, receiptId) async {
  final repo = ref.watch(receiptRepositoryProvider);
  final sub = repo.updates.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return repo.getReceiptDetails(receiptId);
});

final receiptsSearchQueryProvider = StateProvider<String>((ref) => '');
final receiptsFilterMonthProvider = StateProvider<DateTime?>((ref) => null);
final receiptsAmountRangeProvider = StateProvider<RangeValues>((ref) => const RangeValues(0, 1000));

final filteredReceiptsProvider = StreamProvider.autoDispose<List<ReceiptRow>>((ref) {
  final repo = ref.watch(receiptRepositoryProvider);
  final query = ref.watch(receiptsSearchQueryProvider);
  final monthFilter = ref.watch(receiptsFilterMonthProvider);
  final amountRange = ref.watch(receiptsAmountRangeProvider);
  final normalizedQuery = query.trim().toLowerCase();

  return repo.watchAllReceipts().map((receipts) {
    return receipts.where((receipt) {
      final matchesQuery = normalizedQuery.isEmpty ||
          receipt.merchantName.toLowerCase().contains(normalizedQuery) ||
          DateFormat('yyyy-MM-dd').format(receipt.purchaseTimestamp).contains(normalizedQuery);

      final matchesMonth = monthFilter == null
          ? true
          : (receipt.purchaseTimestamp.year == monthFilter.year &&
              receipt.purchaseTimestamp.month == monthFilter.month);

      final total = receipt.totalGross;
      final matchesAmount = total >= amountRange.start && total <= amountRange.end;

      return matchesQuery && matchesMonth && matchesAmount;
    }).toList();
  });
});

class SentryEnabledNotifier extends StateNotifier<bool> {
  SentryEnabledNotifier(this._repository, bool initialState)
      : super(initialState);

  final SettingsRepository _repository;

  Future<void> setEnabled(bool value) async {
    if (state == value) {
      return;
    }
    state = value;
    await _repository.setSentryEnabled(value);
  }
}

final sentryEnabledProvider =
    StateNotifierProvider<SentryEnabledNotifier, bool>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SentryEnabledNotifier(repository, false);
});

final importStatusProvider = StateProvider<String?>((ref) => null);
