import 'package:flutter/material.dart';
import 'package:receipts/l10n/app_localizations.dart';

import 'package:receipts/theme.dart';

class ReceiptDetailsActionButtons extends StatelessWidget {
  const ReceiptDetailsActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.pdfOpenNotImplemented)),
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(t.openPdf),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(t.recategorizationNotImplemented)),
              );
            },
            icon: const Icon(Icons.category),
            label: Text(t.recategorize),
          ),
        ),
      ],
    );
  }
}
