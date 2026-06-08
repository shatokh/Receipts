import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/features/receipt_details/receipt_details_view_model.dart';
import 'package:receipts/features/receipt_details/widgets/receipt_details_content.dart';
import 'package:receipts/features/receipt_details/widgets/receipt_details_states.dart';

class ReceiptDetailsView extends ConsumerWidget {
  const ReceiptDetailsView({super.key, required this.receiptId});

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(receiptDetailsProvider(receiptId));

    return detailsAsync.when(
      data: (details) => ReceiptDetailsContent(
        viewModel: ReceiptDetailsViewModel.fromDetails(details),
      ),
      loading: () => const ReceiptDetailsLoadingState(),
      error: (error, _) => ReceiptDetailsErrorState(error: error),
    );
  }
}
