import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:receipts/l10n/app_localizations.dart';

import 'package:receipts/domain/models/dashboard_kpis.dart';
import 'package:receipts/theme.dart';

class DashboardKpiCards extends StatelessWidget {
  const DashboardKpiCards({super.key, required this.kpis});

  final AsyncValue<DashboardKpis> kpis;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'PLN ',
      decimalDigits: 2,
    );
    final t = AppLocalizations.of(context)!;
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
          child: _KpiCard(
            title: t.totalLast30Days,
            value: totalValue,
            isLoading: isLoading && data == null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _KpiCard(
            title: t.averageReceipt,
            value: averageValue,
            isLoading: isLoading && data == null,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _KpiCard(
            title: t.receiptsMetricLabel,
            value: receiptsValue,
            isLoading: isLoading && data == null,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
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
