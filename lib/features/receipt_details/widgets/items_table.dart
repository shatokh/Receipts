import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:receipts/l10n/app_localizations.dart';

import 'package:receipts/domain/models/line_item.dart';
import 'package:receipts/theme.dart';

class ItemsTable extends StatelessWidget {
  const ItemsTable({super.key, required this.items});

  final List<LineItem> items;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'PLN ',
      decimalDigits: 2,
    );

    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            AppLocalizations.of(context)!.noLineItems,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _TableHeader(),
            const Divider(),
            ...items.map(
              (item) => _ItemRow(
                item: item,
                currencyFormat: currencyFormat,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            t.itemHeader,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            t.quantityPriceHeader,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            t.vatHeader,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            t.totalHeader,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.currencyFormat,
  });

  final LineItem item;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final isDiscount = item.discount > 0 || item.total < 0;
    final quantityText = isDiscount
        ? '—'
        : '${_formatQuantity(item.quantity)} × ${currencyFormat.format(item.unitPrice)}';
    final vatText =
        isDiscount ? '—' : '${(item.vatRate * 100).toStringAsFixed(0)}%';
    final totalText = currencyFormat.format(item.total);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDiscount ? AppColors.success : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              quantityText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              vatText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              totalText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDiscount ? AppColors.success : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toStringAsFixed(0);
    }
    return quantity.toStringAsFixed(2);
  }
}
