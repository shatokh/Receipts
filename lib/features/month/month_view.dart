import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/domain/models/month_overview.dart';
import 'package:receipts/domain/models/monthly_total.dart';
import 'package:receipts/domain/models/receipt_row.dart';
import 'package:receipts/theme.dart';

class MonthView extends ConsumerWidget {
  const MonthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthlyTotalsAsync = ref.watch(monthlyTotalsProvider);
    final monthOverviewAsync = ref.watch(monthOverviewProvider(selectedMonth));
    final receiptsAsync = ref.watch(receiptsByMonthProvider(selectedMonth));
    final monthFormat = DateFormat('MMMM yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'PLN ',
      decimalDigits: 2,
    );

    monthlyTotalsAsync.whenData(
      (totals) => _ensureSelectedMonthIsAvailable(ref, totals),
    );

    final dropdownMonths = monthlyTotalsAsync.maybeWhen(
      data: (totals) => _buildDropdownMonths(totals, selectedMonth),
      orElse: () => [DateTime(selectedMonth.year, selectedMonth.month)],
    );

    final overviewData = monthOverviewAsync.asData?.value;
    final totalValue =
        overviewData != null ? currencyFormat.format(overviewData.total) : '—';
    final receiptsCount = overviewData?.receiptsCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Month overview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MonthPicker(
              months: dropdownMonths,
              selectedMonth: DateTime(selectedMonth.year, selectedMonth.month),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Spending by category — ${monthFormat.format(selectedMonth)}',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _CategoryBreakdown(overview: monthOverviewAsync),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Total — ${monthFormat.format(selectedMonth)}',
                    value: totalValue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MetricCard(
                    title: 'Receipts',
                    value: '$receiptsCount',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Recent receipts',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            receiptsAsync.when(
              data: (receipts) {
                if (receipts.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'No receipts recorded for this month yet',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: receipts
                      .take(5)
                      .map((receipt) => _ReceiptTile(
                            receipt: receipt,
                            currencyFormat: currencyFormat,
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Unable to load receipts: $error',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => context.go('/receipts'),
                child: Text('Show all receipts ($receiptsCount)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _ensureSelectedMonthIsAvailable(
    WidgetRef ref,
    List<MonthlyTotal> totals,
  ) {
    if (totals.isEmpty) {
      return;
    }

    final current = ref.read(selectedMonthProvider);
    final normalizedCurrent = DateTime(current.year, current.month);
    final monthsWithData = totals
        .where((total) => total.total > 0)
        .map((total) => DateTime(total.year, total.month))
        .toList();

    if (monthsWithData.isEmpty) {
      return;
    }

    final hasCurrent =
        monthsWithData.any((month) => _isSameMonth(month, normalizedCurrent));
    if (!hasCurrent) {
      ref.read(selectedMonthProvider.notifier).state = monthsWithData.last;
    }
  }

  List<DateTime> _buildDropdownMonths(
    List<MonthlyTotal> totals,
    DateTime selectedMonth,
  ) {
    final normalizedSelected =
        DateTime(selectedMonth.year, selectedMonth.month);
    final uniqueMonths = <DateTime>{};

    for (final total in totals) {
      if (total.total > 0) {
        uniqueMonths.add(DateTime(total.year, total.month));
      }
    }

    if (uniqueMonths.isEmpty) {
      uniqueMonths
          .addAll(totals.map((total) => DateTime(total.year, total.month)));
    }

    uniqueMonths.add(normalizedSelected);
    final months = uniqueMonths.toList()..sort((a, b) => a.compareTo(b));
    return months;
  }

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}

class _MonthPicker extends ConsumerWidget {
  const _MonthPicker({
    required this.months,
    required this.selectedMonth,
  });

  final List<DateTime> months;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthFormat = DateFormat('MMMM yyyy');
    final value = months.firstWhere(
      (month) =>
          month.year == selectedMonth.year &&
          month.month == selectedMonth.month,
      orElse: () => selectedMonth,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<DateTime>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: months
            .map(
              (month) => DropdownMenuItem(
                value: month,
                child: Text(monthFormat.format(month)),
              ),
            )
            .toList(),
        onChanged: (month) {
          if (month != null) {
            ref.read(selectedMonthProvider.notifier).state = month;
          }
        },
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.overview});

  final AsyncValue<MonthOverview> overview;

  @override
  Widget build(BuildContext context) {
    return overview.when(
      data: (data) {
        final hasSpending =
            data.topCategories.any((category) => category.amount > 0);

        if (!hasSpending) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'No categorized spending for this month yet',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        final maxAmount = data.maxCategoryAmount;
        final currencyFormat = NumberFormat.currency(
          locale: 'en_US',
          symbol: 'PLN ',
          decimalDigits: 2,
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                ...data.topCategories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _CategoryBar(
                      name: category.categoryName,
                      amount: category.amount,
                      maxAmount: maxAmount,
                      formattedAmount: currencyFormat.format(category.amount),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Total — ${currencyFormat.format(data.total)}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Unable to load categories: $error',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.name,
    required this.amount,
    required this.maxAmount,
    required this.formattedAmount,
  });

  final String name;
  final double amount;
  final double maxAmount;
  final String formattedAmount;

  @override
  Widget build(BuildContext context) {
    final percentage = maxAmount <= 0 ? 0.0 : amount / maxAmount;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            name,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        Text(
          formattedAmount,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({
    required this.receipt,
    required this.currencyFormat,
  });

  final ReceiptRow receipt;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      child: ListTile(
        title: Text(
          receipt.merchantName,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          dateFormat.format(receipt.purchaseTimestamp),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Text(
          currencyFormat.format(receipt.totalGross),
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () => context.go('/receipt/${receipt.id}'),
      ),
    );
  }
}
