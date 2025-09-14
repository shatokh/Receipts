import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:biedronka_expenses/theme.dart';
import 'package:biedronka_expenses/data/demo_data.dart';

class ReceiptDetailsView extends ConsumerWidget {
  final String receiptId;

  const ReceiptDetailsView({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For demo, use hardcoded data for the max receipt
    final isMaxReceipt = receiptId == 'receipt_max_august';
    final lineItems = isMaxReceipt ? DemoData.getMaxReceiptItems() : <dynamic>[];
    final receipt = isMaxReceipt 
        ? DemoData.getAugust2025Receipts().firstWhere((r) => r.id == receiptId)
        : null;
    
    if (receipt == null) {
      return _ErrorState(context);
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReceiptHeader(receipt: receipt),
            const SizedBox(height: AppSpacing.lg),
            _ItemsTable(items: lineItems),
            const SizedBox(height: AppSpacing.lg),
            _VATSummary(),
            const SizedBox(height: AppSpacing.lg),
            _ActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _ErrorState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
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
              'Receipt not found',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This receipt may have been deleted or moved',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).go('/receipts'),
              child: const Text('Back to receipts'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptHeader extends StatelessWidget {
  final dynamic receipt;

  const _ReceiptHeader({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'PLN ', decimalDigits: 2);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biedronka',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              dateFormat.format(receipt.purchaseTimestamp),
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              currencyFormat.format(receipt.totalGross),
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsTable extends StatelessWidget {
  final List<dynamic> items;

  const _ItemsTable({required this.items});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'PLN ', decimalDigits: 2);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _TableHeader(),
            const Divider(),
            ...items.map((item) => _ItemRow(
              name: item.name,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              vatRate: item.vatRate,
              total: item.total,
              currencyFormat: currencyFormat,
            )),
          ],
        ),
      ),
    );
  }

  Widget _TableHeader() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            'Item',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Qty × Price',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            'VAT',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Text(
            'Total',
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
  final String name;
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double total;
  final NumberFormat currencyFormat;

  const _ItemRow({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.vatRate,
    required this.total,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isDiscount = name.toLowerCase().contains('rabat');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDiscount ? AppColors.success : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              isDiscount ? '—' : '${quantity.toString()} × ${currencyFormat.format(unitPrice)}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              isDiscount ? '—' : '${(vatRate * 100).round()}%',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              currencyFormat.format(total),
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
}

class _VATSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'VAT total:',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'PLN 3.20',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF opening not implemented in demo')),
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Open PDF'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Re-categorization not implemented in demo')),
              );
            },
            icon: const Icon(Icons.category),
            label: const Text('Re-categorize'),
          ),
        ),
      ],
    );
  }
}