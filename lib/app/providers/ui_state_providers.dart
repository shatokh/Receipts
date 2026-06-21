import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receipts/app/providers/repository_providers.dart';
import 'package:receipts/application/receipts/receipts_filter_state.dart';
import 'package:receipts/domain/models/receipt_row.dart';
import 'package:receipts/domain/value_objects/amount_range.dart';

final receiptsSearchQueryProvider = StateProvider<String>((ref) => '');
final receiptsFilterMonthProvider = StateProvider<DateTime?>((ref) => null);
final receiptsAmountRangeProvider =
    StateProvider<AmountRange>((ref) => AmountRange.receiptFilterDefault);

final filteredReceiptsProvider =
    StreamProvider.autoDispose<List<ReceiptRow>>((ref) {
  final repo = ref.watch(receiptRepositoryProvider);
  final query = ref.watch(receiptsSearchQueryProvider);
  final monthFilter = ref.watch(receiptsFilterMonthProvider);
  final amountRange = ref.watch(receiptsAmountRangeProvider);
  final filter = ReceiptsFilterState(
    query: query,
    month: monthFilter,
    amountRange: amountRange,
  );

  return repo.watchAllReceipts().map((receipts) {
    return filter.apply(receipts);
  });
});
