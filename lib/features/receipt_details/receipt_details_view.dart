import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/domain/category_definitions.dart';
import 'package:receipts/features/receipt_details/receipt_details_view_model.dart';
import 'package:receipts/features/receipt_details/widgets/receipt_details_content.dart';
import 'package:receipts/features/receipt_details/widgets/receipt_details_states.dart';
import 'package:receipts/l10n/app_localizations.dart';
import 'package:receipts/l10n/app_localizations_extensions.dart';
import 'package:receipts/theme.dart';

typedef ReceiptDeletion = Future<void> Function(String receiptId);
typedef LineItemCategoryUpdate = Future<void> Function(
  String lineItemId,
  String categoryId,
);
typedef ReceiptSourceOpen = Future<void> Function(String sourceUri);

class ReceiptDetailsView extends ConsumerStatefulWidget {
  const ReceiptDetailsView({
    super.key,
    required this.receiptId,
    this.onDelete,
    this.onUpdateLineItemCategory,
    this.onOpenSource,
  });

  final String receiptId;
  final ReceiptDeletion? onDelete;
  final LineItemCategoryUpdate? onUpdateLineItemCategory;
  final ReceiptSourceOpen? onOpenSource;

  @override
  ConsumerState<ReceiptDetailsView> createState() => _ReceiptDetailsViewState();
}

class _ReceiptDetailsViewState extends ConsumerState<ReceiptDetailsView> {
  var _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(receiptDetailsProvider(widget.receiptId));

    return detailsAsync.when(
      data: (details) {
        final viewModel = ReceiptDetailsViewModel.fromDetails(details);
        final sourceUri = details.receipt.sourceUri;
        return ReceiptDetailsContent(
          viewModel: viewModel,
          onDelete: _isDeleting ? null : _confirmAndDelete,
          onOpenPdf: _isOpeningSource || sourceUri == null || sourceUri.isEmpty
              ? null
              : () => _openSource(sourceUri),
          onRecategorize: _isRecategorizing || !viewModel.hasLineItems
              ? null
              : () => _selectItemAndCategory(viewModel.items),
        );
      },
      loading: () => const ReceiptDetailsLoadingState(),
      error: (error, _) => ReceiptDetailsErrorState(error: error),
    );
  }

  var _isRecategorizing = false;
  var _isOpeningSource = false;

  Future<void> _openSource(String sourceUri) async {
    final t = AppLocalizations.of(context)!;
    setState(() => _isOpeningSource = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await (widget.onOpenSource ??
          ref.read(receiptSourceOpenerProvider).open)(sourceUri);
    } catch (_) {
      if (mounted) {
        setState(() => _isOpeningSource = false);
        messenger.showSnackBar(SnackBar(content: Text(t.sourceOpenFailed)));
      }
      return;
    }

    if (mounted) {
      setState(() => _isOpeningSource = false);
    }
  }

  Future<void> _selectItemAndCategory(
    List<ReceiptLineItemViewModel> items,
  ) async {
    final t = AppLocalizations.of(context)!;
    final selectedItem = await showDialog<ReceiptLineItemViewModel>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.selectItemToRecategorize),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final item in items)
                ListTile(
                  title: Text(item.name),
                  subtitle: Text(t.categoryLabel(item.categoryId)),
                  onTap: () => Navigator.of(dialogContext).pop(item),
                ),
            ],
          ),
        ),
      ),
    );
    if (selectedItem == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    final selectedCategoryId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.selectCategory),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final category in categoryDefinitions)
                ListTile(
                  title: Text(t.categoryLabel(category.id)),
                  trailing: category.id == selectedItem.categoryId
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () => Navigator.of(dialogContext).pop(category.id),
                ),
            ],
          ),
        ),
      ),
    );
    if (selectedCategoryId == null ||
        selectedCategoryId == selectedItem.categoryId) {
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() => _isRecategorizing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await (widget.onUpdateLineItemCategory ??
          ref.read(receiptRepositoryProvider).updateLineItemCategory)(
        selectedItem.id,
        selectedCategoryId,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isRecategorizing = false);
        messenger.showSnackBar(
          SnackBar(content: Text(t.categoryUpdateFailed)),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isRecategorizing = false);
      messenger.showSnackBar(SnackBar(content: Text(t.categoryUpdated)));
    }
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
