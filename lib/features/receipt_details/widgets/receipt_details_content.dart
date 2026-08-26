import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:receipts/l10n/app_localizations.dart';

import 'package:receipts/features/receipt_details/receipt_details_view_model.dart';
import 'package:receipts/features/receipt_details/widgets/action_buttons.dart';
import 'package:receipts/features/receipt_details/widgets/items_table.dart';
import 'package:receipts/features/receipt_details/widgets/receipt_header.dart';
import 'package:receipts/features/receipt_details/widgets/vat_summary.dart';
import 'package:receipts/theme.dart';

class ReceiptDetailsContent extends StatelessWidget {
  const ReceiptDetailsContent({
    super.key,
    required this.viewModel,
    required this.onDelete,
    required this.onOpenPdf,
    required this.onRecategorize,
  });

  final ReceiptDetailsViewModel viewModel;
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onOpenPdf;
  final Future<void> Function()? onRecategorize;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.receiptTitle),
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
            ReceiptHeader(viewModel: viewModel),
            const SizedBox(height: AppSpacing.lg),
            ItemsTable(items: viewModel.items),
            const SizedBox(height: AppSpacing.lg),
            VatSummary(totalVatText: viewModel.totalVatText),
            const SizedBox(height: AppSpacing.lg),
            ReceiptDetailsActionButtons(
              onDelete: onDelete,
              onOpenPdf: onOpenPdf,
              onRecategorize: onRecategorize,
            ),
          ],
        ),
      ),
    );
  }
}
