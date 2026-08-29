import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:receipts/app/app_test_keys.dart';
import 'package:receipts/core/formatting/app_formatters.dart';
import 'package:receipts/l10n/app_localizations.dart';

import 'package:receipts/domain/models/receipt_row.dart';
import 'package:receipts/theme.dart';

class ReceiptList extends StatelessWidget {
  const ReceiptList({
    super.key,
    required this.receipts,
    required this.currencyFormat,
  });

  final AsyncValue<List<ReceiptRow>> receipts;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return receipts.when(
      data: (receipts) {
        if (receipts.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                t.noReceiptsForMonth,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return Semantics(
          container: true,
          identifier: receipts.length == 1
              ? AppTestSemanticsIds.monthSingleReceipt
              : AppTestSemanticsIds.monthReceipts,
          child: Column(
            children: receipts
                .take(5)
                .map((receipt) => _ReceiptTile(
                      receipt: receipt,
                      currencyFormat: currencyFormat,
                    ))
                .toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            t.unableToLoadReceipts('$error'),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.error,
            ),
          ),
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
    final dateFormat = AppFormatters.receiptDateTime();

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
