import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receipts/app/providers/repository_providers.dart';
import 'package:receipts/application/receipts/receipts_filter_state.dart';
import 'package:receipts/domain/models/receipt_row.dart';

final receiptsSearchQueryProvider = StateProvider<String>((ref) => '');
final receiptsFilterMonthProvider = StateProvider<DateTime?>((ref) => null);
final receiptsAmountRangeProvider =
    StateProvider<RangeValues>((ref) => const RangeValues(0, 1000));

final filteredReceiptsProvider =
    StreamProvider.autoDispose<List<ReceiptRow>>((ref) {
  final repo = ref.watch(receiptRepositoryProvider);
  final query = ref.watch(receiptsSearchQueryProvider);
  final monthFilter = ref.watch(receiptsFilterMonthProvider);
  final amountRange = ref.watch(receiptsAmountRangeProvider);
  final filter = ReceiptsFilterState(
    query: query,
    month: monthFilter,
    minAmount: amountRange.start,
    maxAmount: amountRange.end,
  );

  return repo.watchAllReceipts().map((receipts) {
    return filter.apply(receipts);
  });
});
