import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:biedronka_expenses/theme.dart';
import 'package:biedronka_expenses/app/providers.dart';
import 'package:biedronka_expenses/data/demo_data.dart';

class MonthView extends ConsumerWidget {
  const MonthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(currentMonthProvider);
    final monthFormat = DateFormat('MMMM yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'PLN ', decimalDigits: 2);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Month overview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MonthPicker(),
            const SizedBox(height: AppSpacing.lg),
            _CategoryBreakdown(),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Total — ${monthFormat.format(selectedMonth)}',
                    value: 'PLN 1,250.00',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MetricCard(
                    title: 'Receipts',
                    value: '15',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Recent receipts',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ReceiptsList(),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: () => context.go('/receipts'),
                child: const Text('Show all receipts (15)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthPicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(currentMonthProvider);
    final monthFormat = DateFormat('MMMM yyyy');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<DateTime>(
        value: selectedMonth,
        isExpanded: true,
        underline: const SizedBox.shrink(),
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
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = DemoData.getTopCategoriesAugust2025();
    final maxAmount = categories.values.reduce((a, b) => a > b ? a : b);
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'PLN ', decimalDigits: 2);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
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
        ),
      ),
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({required this.title, required this.value});

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

class _ReceiptsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final receipts = DemoData.getAugust2025Receipts();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'PLN ', decimalDigits: 2);
    
    return Column(
      children: receipts.take(5).map((receipt) => Card(
        child: ListTile(
          title: Text(
            'Biedronka',
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
      )).toList(),
    );
  }
}