import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/features/receipt_details/receipt_details_view_model.dart';
import 'package:receipts/features/receipt_details/widgets/receipt_details_content.dart';
import 'package:receipts/features/receipt_details/widgets/receipt_details_states.dart';
import 'package:receipts/l10n/app_localizations.dart';
import 'package:receipts/theme.dart';

typedef ReceiptDeletion = Future<void> Function(String receiptId);

class ReceiptDetailsView extends ConsumerStatefulWidget {
  const ReceiptDetailsView({
    super.key,
    required this.receiptId,
    this.onDelete,
  });

  final String receiptId;
  final ReceiptDeletion? onDelete;

  @override
  ConsumerState<ReceiptDetailsView> createState() => _ReceiptDetailsViewState();
}

class _ReceiptDetailsViewState extends ConsumerState<ReceiptDetailsView> {
  var _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(receiptDetailsProvider(widget.receiptId));

    return detailsAsync.when(
      data: (details) => ReceiptDetailsContent(
        viewModel: ReceiptDetailsViewModel.fromDetails(details),
        onDelete: _isDeleting ? null : _confirmAndDelete,
      ),
      loading: () => const ReceiptDetailsLoadingState(),
      error: (error, _) => ReceiptDetailsErrorState(error: error),
    );
  }

  Future<void> _confirmAndDelete() async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.deleteReceiptDialogTitle),
        content: Text(t.deleteReceiptDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(t.deleteReceipt),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isDeleting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await (widget.onDelete ?? ref.read(receiptRepositoryProvider).deleteReceipt)(
        widget.receiptId,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isDeleting = false);
        messenger.showSnackBar(SnackBar(content: Text(t.deleteReceiptFailed)));
      }
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(t.deleteReceiptSuccess)));
  }
}
