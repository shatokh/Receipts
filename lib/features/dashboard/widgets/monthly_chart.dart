import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:receipts/core/formatting/app_formatters.dart';
import 'package:receipts/l10n/app_localizations.dart';
import 'package:receipts/l10n/app_localizations_extensions.dart';

import 'package:receipts/domain/models/monthly_total.dart';
import 'package:receipts/theme.dart';

class MonthlyChart extends StatelessWidget {
  const MonthlyChart({super.key, required this.totals});

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
    final currencyFormat = AppFormatters.receiptCurrency();
    final t = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.monthlySpend,
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
                        final monthName = t.formatMonthYearShort(
                          DateTime(month.year, month.month),
                        );
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
                              t.formatMonthAbbreviated(
                                DateTime(month.year, month.month),
                              ),
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
