import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:receipts/core/formatting/app_formatters.dart';

import 'package:receipts/domain/models/receipt_row.dart';
import 'package:receipts/theme.dart';

class ReceiptsList extends StatelessWidget {
  const ReceiptsList({super.key, required this.receipts});

  final List<ReceiptRow> receipts;

  @override
  Widget build(BuildContext context) {
    final dateFormat = AppFormatters.receiptDateTime();
    final currencyFormat = AppFormatters.receiptCurrency();

    return ListView.separated(
      key: const ValueKey('receipt_list'),
      itemCount: receipts.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final receipt = receipts[index];
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(
                Icons.receipt,
                color: Colors.white,
                size: 20,
              ),
            ),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currencyFormat.format(receipt.totalGross),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            onTap: () => context.go('/receipt/${receipt.id}'),
          ),
        );
      },
    );
  }
}
