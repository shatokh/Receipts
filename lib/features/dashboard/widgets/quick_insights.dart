import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:receipts/l10n/app_localizations.dart';
import 'package:receipts/l10n/app_localizations_extensions.dart';

import 'package:receipts/domain/models/month_overview.dart';
import 'package:receipts/domain/models/receipt_row.dart';
import 'package:receipts/theme.dart';

class QuickInsights extends StatelessWidget {
  const QuickInsights({
    super.key,
    required this.overview,
  });

  final AsyncValue<MonthOverview> overview;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return overview.when(
      data: (data) {
        final currencyFormat = NumberFormat.currency(
          locale: 'en_US',
          symbol: 'PLN ',
          decimalDigits: 2,
        );

        final ReceiptRow? maxReceipt = data.maxReceipt;
        final maxReceiptSubtitle = maxReceipt == null
            ? t.noReceiptsThisMonth
            : t.receiptMerchantAndDate(
                maxReceipt.merchantName,
                DateFormat('yyyy-MM-dd HH:mm')
                    .format(maxReceipt.purchaseTimestamp),
              );

        final receiptsLabel = t.receiptCount(data.receiptsCount);

        return Row(
          children: [
            Expanded(
              child: _InsightCard(
                title: t.maxReceiptForMonth(
                  t.formatMonthYear(data.month),
                ),
                value: maxReceipt == null
                    ? '—'
                    : currencyFormat.format(maxReceipt.totalGross),
                subtitle: maxReceiptSubtitle,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _InsightCard(
                title: t.totalForMonth(
                  t.formatMonthYear(data.month),
                ),
                value: currencyFormat.format(data.total),
                subtitle: receiptsLabel,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Row(
        children: [
          Expanded(
            child: _InsightCard(
              title: t.maxReceipt,
              value: '—',
              subtitle: t.unableToLoadData,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _InsightCard(
              title: t.totalLabel,
              value: '—',
              subtitle: t.unableToLoadData,
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
