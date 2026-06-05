import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipts/l10n/app_localizations.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/application/receipts/receipts_filter_state.dart';
import 'package:receipts/features/receipts/widgets/receipts_empty_state.dart';
import 'package:receipts/features/receipts/widgets/receipts_list.dart';
import 'package:receipts/features/receipts/widgets/search_and_filters.dart';
import 'package:receipts/theme.dart';

class ReceiptsView extends ConsumerWidget {
  const ReceiptsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final filteredReceiptsAsync = ref.watch(filteredReceiptsProvider);
    final searchQuery = ref.watch(receiptsSearchQueryProvider);
    final selectedMonth = ref.watch(receiptsFilterMonthProvider);
    final amountRange = ref.watch(receiptsAmountRangeProvider);
    final monthlyTotalsAsync = ref.watch(monthlyTotalsProvider);

    final monthOptions = monthlyTotalsAsync.maybeWhen(
      data: ReceiptsFilterState.buildFilterMonths,
      orElse: () => <DateTime>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(t.receiptsTitle),
      ),
      body: Column(
        children: [
          SearchAndFilters(
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
                  ? const ReceiptsEmptyState()
                  : ReceiptsList(receipts: receipts),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  t.unableToLoadReceipts('$error'),
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
}
