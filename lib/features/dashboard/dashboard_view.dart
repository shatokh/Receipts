import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/domain/models/dashboard_kpis.dart';
import 'package:receipts/domain/models/month_overview.dart';
import 'package:receipts/domain/models/monthly_total.dart';
import 'package:receipts/domain/models/receipt_row.dart';
import 'package:receipts/theme.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final monthlyTotalsAsync = ref.watch(monthlyTotalsProvider);
    final monthOverviewAsync = ref.watch(monthOverviewProvider(selectedMonth));
    final kpisAsync = ref.watch(dashboardKpisProvider);
    final monthFormat = DateFormat('MMMM yyyy');

    monthlyTotalsAsync.whenData(_ensureSelectedMonthIsAvailable);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending dashboard'),
        actions: [
          IconButton(
            key: const ValueKey('nav_import_action'),
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/import'),
            tooltip: 'Import PDF',
          ),
        ],
      ),
      body: monthlyTotalsAsync.when(
        data: (totals) {
          if (totals.isEmpty) {
            return _DashboardEmptyState(
              onImport: () => context.go('/import'),
            );
          }

          final dropdownMonths = _buildDropdownMonths(totals, selectedMonth);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KPICards(kpis: kpisAsync),
                const SizedBox(height: AppSpacing.lg),
                _MonthlyChart(totals: totals),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Selected month',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _MonthDropdown(
                      months: dropdownMonths,
                      selectedMonth:
                          DateTime(selectedMonth.year, selectedMonth.month),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.divider.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'All data is processed on device',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Top categories — ${monthFormat.format(selectedMonth)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _TopCategoriesSection(
                  overview: monthOverviewAsync,
                ),
                const SizedBox(height: AppSpacing.lg),
                _QuickInsights(
                  overview: monthOverviewAsync,
                  monthFormat: monthFormat,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DashboardErrorState(error: error),
      ),
    );
  }

  void _ensureSelectedMonthIsAvailable(List<MonthlyTotal> totals) {
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
      List<MonthlyTotal> totals, DateTime selectedMonth) {
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

class _KPICards extends StatelessWidget {
  const _KPICards({required this.kpis});

  final AsyncValue<DashboardKpis> kpis;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'PLN ',
      decimalDigits: 2,
    );
    final data = kpis.asData?.value;
    final isLoading = kpis.isLoading;

    final totalValue =
        data != null ? currencyFormat.format(data.totalLast30Days) : '—';
    final averageValue =
        data != null ? currencyFormat.format(data.averageReceipt) : '—';
    final receiptsValue = data != null ? '${data.receiptsCount}' : '—';

    return Row(
      children: [
        Expanded(
          child: _KPICard(
            title: 'Total (30d)',
            value: totalValue,
            isLoading: isLoading && data == null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _KPICard(
            title: 'Average receipt',
            value: averageValue,
            isLoading: isLoading && data == null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _KPICard(
            title: 'Receipts',
            value: receiptsValue,
            isLoading: isLoading && data == null,
          ),
        ),
      ],
    );
  }
}

class _KPICard extends StatelessWidget {
  const _KPICard({
    required this.title,
    required this.value,
    required this.isLoading,
  });

  final String title;
  final String value;
  final bool isLoading;

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
            if (isLoading)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
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

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.totals});

  final List<MonthlyTotal> totals;

  @override
  Widget build(BuildContext context) {
    const chartHeight = 200.0;
    final values = totals.map((total) => total.total).toList();
    final maxTotal = values.isEmpty
        ? 0.0
        : values.reduce((value, element) => max(value, element));
    final maxY = maxTotal <= 0 ? 1.0 : maxTotal * 1.1;
    final labelThreshold = maxY * (18 / chartHeight);
    final currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'PLN ',
      decimalDigits: 2,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly spend',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: chartHeight,
              child: BarChart(
                key: const ValueKey('chart_view'),
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final month = totals[groupIndex];
                        final monthName = DateFormat('MMM yyyy')
                            .format(DateTime(month.year, month.month));
                        return BarTooltipItem(
                          '$monthName\n${currencyFormat.format(month.total)}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < totals.length) {
                            final month = totals[index];
                            return Text(
                              DateFormat('MMM')
                                  .format(DateTime(month.year, month.month)),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= totals.length) {
                            return const SizedBox.shrink();
                          }
                          final amount = totals[index].total;
                          if (amount <= 0 || amount < labelThreshold) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              currencyFormat.format(amount),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: totals.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.total,
                          color: AppColors.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthDropdown extends ConsumerWidget {
  const _MonthDropdown({
    required this.months,
    required this.selectedMonth,
  });

  final List<DateTime> months;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthFormat = DateFormat('MMMM yyyy');
    final normalizedSelected =
        DateTime(selectedMonth.year, selectedMonth.month);

    final value = months.firstWhere(
      (month) =>
          month.year == normalizedSelected.year &&
          month.month == normalizedSelected.month,
      orElse: () => normalizedSelected,
    );

    return DropdownButton<DateTime>(
      value: value,
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
    );
  }
}

class _TopCategoriesSection extends StatelessWidget {
  const _TopCategoriesSection({required this.overview});

  final AsyncValue<MonthOverview> overview;

  @override
  Widget build(BuildContext context) {
    return overview.when(
      data: (data) {
        if (data.topCategories.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'No categories yet for this month',
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
                  'Top 5 of ${currencyFormat.format(data.total)}',
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
            'Unable to load categories',
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

class _QuickInsights extends StatelessWidget {
  const _QuickInsights({
    required this.overview,
    required this.monthFormat,
  });

  final AsyncValue<MonthOverview> overview;
  final DateFormat monthFormat;

  @override
  Widget build(BuildContext context) {
    return overview.when(
      data: (data) {
        final currencyFormat = NumberFormat.currency(
          locale: 'en_US',
          symbol: 'PLN ',
          decimalDigits: 2,
        );

        final ReceiptRow? maxReceipt = data.maxReceipt;
        final maxReceiptSubtitle = maxReceipt == null
            ? 'No receipts this month'
            : '${maxReceipt.merchantName}, ${DateFormat('yyyy-MM-dd HH:mm').format(maxReceipt.purchaseTimestamp)}';

        final receiptsLabel = data.receiptsCount == 1
            ? '1 receipt'
            : '${data.receiptsCount} receipts';

        return Row(
          children: [
            Expanded(
              child: _InsightCard(
                title: 'Max receipt — ${monthFormat.format(data.month)}',
                value: maxReceipt == null
                    ? '—'
                    : currencyFormat.format(maxReceipt.totalGross),
                subtitle: maxReceiptSubtitle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _InsightCard(
                title: 'Total — ${monthFormat.format(data.month)}',
                value: currencyFormat.format(data.total),
                subtitle: receiptsLabel,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Row(
        children: const [
          Expanded(
            child: _InsightCard(
              title: 'Max receipt',
              value: '—',
              subtitle: 'Unable to load data',
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: _InsightCard(
              title: 'Total',
              value: '—',
              subtitle: 'Unable to load data',
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

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
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bar_chart,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No receipts yet',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Import your first receipt to see analytics',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onImport,
              child: const Text('Import PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Something went wrong',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
