import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:biedronka_expenses/theme.dart';
import 'package:biedronka_expenses/app/providers.dart';
import 'package:biedronka_expenses/data/demo_data.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(currentMonthProvider);
    final monthFormat = DateFormat('MMMM yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/import'),
            tooltip: 'Import PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KPICards(),
            const SizedBox(height: AppSpacing.lg),
            _MonthlyChart(),
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
                _MonthDropdown(),
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
            _TopCategoriesSection(),
            const SizedBox(height: AppSpacing.lg),
            _QuickInsights(),
          ],
        ),
      ),
    );
  }
}

class _KPICards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final kpis = DemoData.getDashboardKPIs();
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'PLN ', decimalDigits: 2);
    
    return Row(
      children: [
        Expanded(
          child: _KPICard(
            title: 'Total (30d)',
            value: currencyFormat.format(kpis['total30d']),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _KPICard(
            title: 'Average receipt',
            value: currencyFormat.format(kpis['averageReceipt']),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _KPICard(
            title: 'Receipts',
            value: '${kpis['receipts']}',
          ),
        ),
      ],
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;

  const _KPICard({required this.title, required this.value});

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

class _MonthlyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = DemoData.getMonthlyTotals();
    
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
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1400,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final month = data[groupIndex];
                        final monthName = DateFormat('MMM yyyy').format(DateTime(month.year, month.month));
                        return BarTooltipItem(
                          '$monthName\nPLN ${NumberFormat('#,##0.00').format(month.total)}',
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
                          if (index >= 0 && index < data.length) {
                            final month = data[index];
                            return Text(
                              DateFormat('MMM').format(DateTime(month.year, month.month)),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: data.asMap().entries.map((entry) {
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
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(currentMonthProvider);
    final monthFormat = DateFormat('MMMM yyyy');
    
    return DropdownButton<DateTime>(
      value: selectedMonth,
      items: [
        DropdownMenuItem(
          value: DateTime(2025, 8),
          child: Text(monthFormat.format(DateTime(2025, 8))),
        ),
        DropdownMenuItem(
          value: DateTime(2025, 7),
          child: Text(monthFormat.format(DateTime(2025, 7))),
        ),
        DropdownMenuItem(
          value: DateTime(2025, 6),
          child: Text(monthFormat.format(DateTime(2025, 6))),
        ),
      ],
      onChanged: (month) {
        if (month != null) {
          ref.read(currentMonthProvider.notifier).state = month;
        }
      },
    );
  }
}

class _TopCategoriesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = DemoData.getTopCategoriesAugust2025();
    final maxAmount = categories.values.reduce((a, b) => a > b ? a : b);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'PLN ', decimalDigits: 2);
    
    return Column(
      children: [
        ...categories.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _CategoryBar(
            name: entry.key,
            amount: entry.value,
            maxAmount: maxAmount,
            formattedAmount: currencyFormat.format(entry.value),
          ),
        )),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Top 5 of PLN 1,250.00',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String name;
  final double amount;
  final double maxAmount;
  final String formattedAmount;

  const _CategoryBar({
    required this.name,
    required this.amount,
    required this.maxAmount,
    required this.formattedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = amount / maxAmount;
    
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
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InsightCard(
            title: 'Max receipt — August 2025',
            value: 'PLN 236.40',
            subtitle: 'Biedronka, 2025-08-14 18:22',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _InsightCard(
            title: 'Total — August 2025',
            value: 'PLN 1,250.00',
            subtitle: '15 receipts',
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

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