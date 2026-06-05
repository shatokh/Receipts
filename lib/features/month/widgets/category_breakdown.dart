import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:receipts/l10n/app_localizations.dart';
import 'package:receipts/l10n/app_localizations_extensions.dart';

import 'package:receipts/domain/models/month_overview.dart';
import 'package:receipts/theme.dart';

class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({super.key, required this.overview});

  final AsyncValue<MonthOverview> overview;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return overview.when(
      data: (data) {
        final hasSpending =
            data.topCategories.any((category) => category.amount > 0);

        if (!hasSpending) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                t.noCategorizedSpending,
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
                      name: t.categoryLabel(category.categoryId),
                      amount: category.amount,
                      maxAmount: maxAmount,
                      formattedAmount: currencyFormat.format(category.amount),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  t.totalWithAmount(
                    currencyFormat.format(data.total),
                  ),
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
            t.unableToLoadCategoriesWithError('$error'),
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
