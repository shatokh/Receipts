import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:receipts/l10n/app_localizations.dart';
import 'package:receipts/l10n/app_localizations_extensions.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/features/month/month_view_model.dart';
import 'package:receipts/features/month/widgets/category_breakdown.dart';
import 'package:receipts/features/month/widgets/metric_card.dart';
import 'package:receipts/features/month/widgets/month_picker.dart';
import 'package:receipts/features/month/widgets/receipt_list.dart';
import 'package:receipts/theme.dart';

class MonthView extends ConsumerWidget {
  const MonthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthlyTotalsAsync = ref.watch(monthlyTotalsProvider);
    final monthOverviewAsync = ref.watch(monthOverviewProvider(selectedMonth));
    final receiptsAsync = ref.watch(receiptsByMonthProvider(selectedMonth));
    final currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'PLN ',
      decimalDigits: 2,
    );

    final viewModel = MonthViewModel.fromData(
      totals: monthlyTotalsAsync.asData?.value,
      selectedMonth: selectedMonth,
      overview: monthOverviewAsync.asData?.value,
    );

    monthlyTotalsAsync.whenData((totals) {
      final nextViewModel = MonthViewModel.fromData(
        totals: totals,
        selectedMonth: selectedMonth,
        overview: monthOverviewAsync.asData?.value,
      );
      final replacementSelectedMonth = nextViewModel.replacementSelectedMonth;
      if (replacementSelectedMonth != null) {
        ref.read(selectedMonthProvider.notifier).state =
            replacementSelectedMonth;
      }
    });

    final totalAmount = viewModel.totalAmount;
    final totalValue =
        totalAmount != null ? currencyFormat.format(totalAmount) : '—';
    final receiptsCount = viewModel.receiptsCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.monthOverviewTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MonthPicker(
              months: viewModel.dropdownMonths,
              selectedMonth: viewModel.normalizedSelectedMonth,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              t.spendingByCategoryForMonth(
                t.formatMonthYear(selectedMonth),
              ),
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            CategoryBreakdown(
              key: const ValueKey('chart_view'),
              overview: monthOverviewAsync,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: t.totalForMonth(
                      t.formatMonthYear(selectedMonth),
                    ),
                    value: totalValue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: MetricCard(
                    title: t.receiptsMetricLabel,
                    value: '$receiptsCount',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              t.recentReceipts,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ReceiptList(
              receipts: receiptsAsync,
              currencyFormat: currencyFormat,
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => context.go('/receipts'),
                child: Text(t.showAllReceipts(receiptsCount)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
