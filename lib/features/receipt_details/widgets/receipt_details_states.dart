import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:receipts/l10n/app_localizations.dart';

import 'package:receipts/theme.dart';

class ReceiptDetailsLoadingState extends StatelessWidget {
  const ReceiptDetailsLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.receiptTitle),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class ReceiptDetailsErrorState extends StatelessWidget {
  const ReceiptDetailsErrorState({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.receiptTitle)),
      body: Center(
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
              t.receiptNotFound,
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
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).go('/receipts'),
              child: Text(t.backToReceipts),
            ),
          ],
        ),
      ),
    );
  }
}
