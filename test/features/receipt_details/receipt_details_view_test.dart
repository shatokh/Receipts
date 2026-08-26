import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/domain/models/line_item.dart';
import 'package:receipts/domain/models/merchant.dart';
import 'package:receipts/domain/models/receipt.dart';
import 'package:receipts/domain/models/receipt_details.dart';
import 'package:receipts/features/receipt_details/receipt_details_view.dart';
import 'package:receipts/l10n/app_localizations.dart';

void main() {
  testWidgets('ReceiptDetailsView renders loading state', (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          receiptDetailsProvider.overrideWith(
            (ref, receiptId) => Future.value(_detailsFor(receiptId)),
          ),
        ],
        child: const ReceiptDetailsView(receiptId: 'receipt-1'),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ReceiptDetailsView renders error state', (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          receiptDetailsProvider.overrideWith(
            (ref, receiptId) => Future.error(StateError('missing receipt')),
          ),
        ],
        child: const ReceiptDetailsView(receiptId: 'receipt-1'),
      ),
    );
    await tester.pump();

    expect(find.text('Receipt not found'), findsOneWidget);
    expect(find.text('Back to receipts'), findsOneWidget);
  });

  testWidgets('ReceiptDetailsView renders receipt details', (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          receiptDetailsProvider.overrideWith((ref, receiptId) async {
            return ReceiptDetails(
              receipt: Receipt(
                id: receiptId,
                merchantId: 'merchant-1',
                purchaseTimestamp: DateTime(2025, 8, 12, 10, 30),
                totalGross: 12.50,
                totalVat: 1.25,
              ),
              merchant: const Merchant(
                id: 'merchant-1',
                name: 'Test Store',
              ),
              items: const [
                LineItem(
                  id: 'item-1',
                  receiptId: 'receipt-1',
                  name: 'Test item',
                  quantity: 1,
                  unit: 'pcs',
                  unitPrice: 12.50,
                  vatRate: 0.1,
                  total: 12.50,
                  categoryId: 'other',
                ),
              ],
            );
          }),
        ],
        child: const ReceiptDetailsView(receiptId: 'receipt-1'),
      ),
    );

    await tester.pump();

    expect(find.text('Receipt'), findsOneWidget);
    expect(find.text('Test Store'), findsOneWidget);
    expect(find.text('Test item'), findsOneWidget);
  });
}

ReceiptDetails _detailsFor(String receiptId) {
  return ReceiptDetails(
    receipt: Receipt(
      id: receiptId,
      merchantId: 'merchant-1',
      purchaseTimestamp: DateTime(2025, 8, 12),
      totalGross: 12.50,
      totalVat: 1.25,
    ),
    merchant: const Merchant(id: 'merchant-1', name: 'Test Store'),
    items: const [],
  );
}

Widget _testApp({
  required Widget child,
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}
