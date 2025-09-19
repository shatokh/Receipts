import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:biedronka_expenses/app/providers.dart';
import 'package:biedronka_expenses/domain/models/monthly_total.dart';
import 'package:biedronka_expenses/domain/models/receipt_row.dart';
import 'package:biedronka_expenses/theme.dart';

class ReceiptsView extends ConsumerWidget {
  const ReceiptsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredReceiptsAsync = ref.watch(filteredReceiptsProvider);
    final searchQuery = ref.watch(receiptsSearchQueryProvider);
    final selectedMonth = ref.watch(receiptsFilterMonthProvider);
    final amountRange = ref.watch(receiptsAmountRangeProvider);
    final monthlyTotalsAsync = ref.watch(monthlyTotalsProvider);

    final monthOptions = monthlyTotalsAsync.maybeWhen(
      data: (totals) => _buildFilterMonths(totals),
      orElse: () => <DateTime>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipts'),
      ),
      body: Column(
        children: [
          _SearchAndFilters(
            searchQuery: searchQuery,
            selectedMonth: selectedMonth,
            amountRange: amountRange,
            monthOptions: monthOptions,
            onSearchChanged: (value) =>
                ref.read(receiptsSearchQueryProvider.notifier).state = value,
            onMonthChanged: (value) =>
                ref.read(receiptsFilterMonthProvider.notifier).state = value,
            onAmountChanged: (value) =>
                ref.read(receiptsAmountRangeProvider.notifier).state = value,
          ),
          Expanded(
            child: filteredReceiptsAsync.when(
              data: (receipts) => receipts.isEmpty
                  ? const _EmptyState()
                  : _ReceiptsList(receipts: receipts),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Unable to load receipts: $error',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _buildFilterMonths(List<MonthlyTotal> totals) {
    final months = <DateTime>{};
    for (final total in totals) {
      if (total.total > 0) {
        months.add(DateTime(total.year, total.month));
      }
    }
    if (months.isEmpty) {
      months.addAll(totals.map((total) => DateTime(total.year, total.month)));
    }
    final list = months.toList()
      ..sort((a, b) => b.compareTo(a));
    return list;
  }
}

class _SearchAndFilters extends ConsumerStatefulWidget {
  const _SearchAndFilters({
    required this.searchQuery,
    required this.selectedMonth,
    required this.amountRange,
    required this.monthOptions,
    required this.onSearchChanged,
    required this.onMonthChanged,
    required this.onAmountChanged,
  });

  final String searchQuery;
  final DateTime? selectedMonth;
  final RangeValues amountRange;
  final List<DateTime> monthOptions;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<DateTime?> onMonthChanged;
  final ValueChanged<RangeValues> onAmountChanged;

  @override
  ConsumerState<_SearchAndFilters> createState() => _SearchAndFiltersState();
}

class _SearchAndFiltersState extends ConsumerState<_SearchAndFilters> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant _SearchAndFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.searchQuery,
        selection: TextSelection.collapsed(offset: widget.searchQuery.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Search by merchant or date',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: widget.onSearchChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<DateTime?>(
                  initialValue: widget.selectedMonth,
                  decoration: const InputDecoration(
                    labelText: 'Month',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All months'),
                    ),
                    ...widget.monthOptions.map(
                      (month) => DropdownMenuItem(
                        value: month,
                        child: Text(DateFormat('MMMM yyyy').format(month)),
                      ),
                    ),
                  ],
                  onChanged: widget.onMonthChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total range: PLN ${widget.amountRange.start.round()} - ${widget.amountRange.end.round()}',
                      style: AppTextStyles.labelSmall,
                    ),
                    RangeSlider(
                      values: widget.amountRange,
                      min: 0,
                      max: 1000,
                      divisions: 20,
                      onChanged: widget.onAmountChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No receipts found',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try adjusting your search or filters',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptsList extends StatelessWidget {
  const _ReceiptsList({required this.receipts});

  final List<ReceiptRow> receipts;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'PLN ',
      decimalDigits: 2,
    );

    return ListView.separated(
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
