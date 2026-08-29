import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/app/app_test_keys.dart';
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
    expect(
      tester
          .getSemantics(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  widget.properties.identifier ==
                      AppTestSemanticsIds.receiptDetails,
            ),
          )
          .identifier,
      AppTestSemanticsIds.receiptDetails,
    );
    expect(find.text('Test Store'), findsOneWidget);
    expect(find.text('Test item'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('openPdfButton')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('ReceiptDetailsView confirms before deleting a receipt',
      (tester) async {
    final deletedIds = <String>[];
    await tester.pumpWidget(
      _testApp(
        overrides: [
          receiptDetailsProvider.overrideWith(
            (ref, receiptId) => Future.value(_detailsFor(receiptId)),
          ),
        ],
        child: ReceiptDetailsView(
          receiptId: 'receipt-1',
          onDelete: (receiptId) async => deletedIds.add(receiptId),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Delete receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Delete receipt?'), findsOneWidget);
    expect(
      find.text(
        'This receipt and its items will be permanently deleted. This action cannot be undone.',
      ),
      findsOneWidget,
    );
    expect(deletedIds, isEmpty);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(deletedIds, isEmpty);

    await tester.tap(find.text('Delete receipt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete receipt').last);
    await tester.pump();

    expect(deletedIds, ['receipt-1']);
  });

  testWidgets('ReceiptDetailsView shows a safe deletion failure message',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          receiptDetailsProvider.overrideWith(
            (ref, receiptId) => Future.value(_detailsFor(receiptId)),
          ),
        ],
        child: ReceiptDetailsView(
          receiptId: 'receipt-1',
          onDelete: (_) async => throw StateError('raw receipt contents'),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Delete receipt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete receipt').last);
    await tester.pump();

    expect(find.text('Could not delete receipt. Try again.'), findsOneWidget);
    expect(find.text('raw receipt contents'), findsNothing);
  });

  testWidgets('ReceiptDetailsView updates the selected line item category',
      (tester) async {
    final updates = <(String, String)>[];
    await tester.pumpWidget(
      _testApp(
        overrides: [
          receiptDetailsProvider.overrideWith(
            (ref, receiptId) => Future.value(_detailsWithItem(receiptId)),
          ),
        ],
        child: ReceiptDetailsView(
          receiptId: 'receipt-1',
          onUpdateLineItemCategory: (lineItemId, categoryId) async {
            updates.add((lineItemId, categoryId));
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Re-categorize'));
    await tester.pumpAndSettle();
    expect(find.text('Select an item'), findsOneWidget);

    await tester.tap(find.text('Milk').last);
    await tester.pumpAndSettle();
    expect(find.text('Select a category'), findsOneWidget);

    await tester.tap(find.text('Fresh Produce & Vegetables'));
    await tester.pump();

    expect(updates, [('item-1', 'fresh_produce')]);
    expect(find.text('Category updated'), findsOneWidget);
  });

  testWidgets('ReceiptDetailsView shows a safe category update failure message',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          receiptDetailsProvider.overrideWith(
            (ref, receiptId) => Future.value(_detailsWithItem(receiptId)),
          ),
        ],
        child: ReceiptDetailsView(
          receiptId: 'receipt-1',
          onUpdateLineItemCategory: (_, __) async {
            throw StateError('raw receipt contents');
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Re-categorize'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Milk').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fresh Produce & Vegetables'));
    await tester.pump();

    expect(find.text('Could not update category. Try again.'), findsOneWidget);
    expect(find.text('raw receipt contents'), findsNothing);
  });

  testWidgets('ReceiptDetailsView opens a stored source URI', (tester) async {
    final openedSources = <String>[];
    await tester.pumpWidget(
      _testApp(
        overrides: [
          receiptDetailsProvider.overrideWith(
            (ref, receiptId) => Future.value(
              _detailsFor(
                receiptId,
                sourceUri: 'content://test.provider/receipt.pdf',
              ),
            ),
          ),
        ],
        child: ReceiptDetailsView(
          receiptId: 'receipt-1',
          onOpenSource: (sourceUri) async {
            openedSources.add(sourceUri);
          },
        ),
      ),
    );
    await tester.pump();

    expect(
      tester
          .getSemantics(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  widget.properties.identifier ==
                      AppTestSemanticsIds.receiptOpenPdf,
            ),
          )
          .identifier,
      AppTestSemanticsIds.receiptOpenPdf,
    );
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('openPdfButton')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Open PDF'));
    await tester.pump();

    expect(openedSources, ['content://test.provider/receipt.pdf']);
  });

  testWidgets('ReceiptDetailsView shows a safe source opening failure message',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          receiptDetailsProvider.overrideWith(
            (ref, receiptId) => Future.value(
              _detailsFor(
                receiptId,
                sourceUri: 'content://test.provider/receipt.pdf',
              ),
            ),
          ),
        ],
        child: ReceiptDetailsView(
          receiptId: 'receipt-1',
          onOpenSource: (_) async {
            throw StateError('content://private/receipt.pdf');
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Open PDF'));
    await tester.pump();

    expect(
      find.text(
        'Could not open the source file. Make sure it is still available.',
      ),
      findsOneWidget,
    );
    expect(find.text('content://private/receipt.pdf'), findsNothing);
  });
}

ReceiptDetails _detailsFor(String receiptId, {String? sourceUri}) {
  return ReceiptDetails(
    receipt: Receipt(
      id: receiptId,
      merchantId: 'merchant-1',
      purchaseTimestamp: DateTime(2025, 8, 12),
      totalGross: 12.50,
      totalVat: 1.25,
      sourceUri: sourceUri,
    ),
    merchant: const Merchant(id: 'merchant-1', name: 'Test Store'),
    items: const [],
  );
}

ReceiptDetails _detailsWithItem(String receiptId) {
  return ReceiptDetails(
    receipt: Receipt(
      id: receiptId,
      merchantId: 'merchant-1',
      purchaseTimestamp: DateTime(2025, 8, 12),
      totalGross: 12.50,
      totalVat: 1.25,
    ),
    merchant: const Merchant(id: 'merchant-1', name: 'Test Store'),
    items: [
      LineItem(
        id: 'item-1',
        receiptId: receiptId,
        name: 'Milk',
        quantity: 1,
        unit: 'pcs',
        unitPrice: 12.50,
        vatRate: 0.1,
        total: 12.50,
        categoryId: 'dairy_eggs_bakery',
      ),
    ],
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
