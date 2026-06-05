import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:receipts/l10n/app_localizations.dart';

import 'package:receipts/domain/models/receipt_details.dart';
import 'package:receipts/features/receipt_details/widgets/action_buttons.dart';
import 'package:receipts/features/receipt_details/widgets/items_table.dart';
import 'package:receipts/features/receipt_details/widgets/receipt_header.dart';
import 'package:receipts/features/receipt_details/widgets/vat_summary.dart';
import 'package:receipts/theme.dart';

class ReceiptDetailsContent extends StatelessWidget {
  const ReceiptDetailsContent({super.key, required this.details});

  final ReceiptDetails details;

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
            ReceiptHeader(details: details),
            const SizedBox(height: AppSpacing.lg),
            ItemsTable(items: details.items),
            const SizedBox(height: AppSpacing.lg),
            VatSummary(totalVat: details.totalVat),
            const SizedBox(height: AppSpacing.lg),
            const ReceiptDetailsActionButtons(),
          ],
        ),
      ),
    );
  }
}
