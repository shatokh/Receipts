import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/app/app_test_keys.dart';
import 'package:receipts/app/providers.dart';
import 'package:receipts/domain/models/monthly_total.dart';
import 'package:receipts/domain/models/receipt_row.dart';
import 'package:receipts/domain/value_objects/amount_range.dart';
import 'package:receipts/features/receipts/receipts_view.dart';
import 'package:receipts/l10n/app_localizations.dart';

void main() {
  testWidgets('ReceiptsView renders loading state', (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: _baseOverrides(
          receipts: Stream.empty(),
          monthlyTotals: Stream.value(const <MonthlyTotal>[]),
        ),
        child: const ReceiptsView(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ReceiptsView renders empty receipts state', (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: _baseOverrides(
          receipts: Stream.value(const []),
          monthlyTotals: Stream.value(const <MonthlyTotal>[]),
        ),
        child: const ReceiptsView(),
      ),
    );

    await tester.pump();

    expect(find.text('Receipts'), findsOneWidget);
    expect(find.text('No receipts found'), findsOneWidget);
  });

  testWidgets('ReceiptsView renders error state', (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: _baseOverrides(
          receipts: Stream.error(StateError('repository unavailable')),
          monthlyTotals: Stream.value(const <MonthlyTotal>[]),
        ),
        child: const ReceiptsView(),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Unable to load receipts:'), findsOneWidget);
  });

  testWidgets('ReceiptsView renders populated receipts', (tester) async {
    final receipt = ReceiptRow(
      id: 'receipt-1',
      merchantId: 'merchant-1',
      merchantName: 'Test Store',
      purchaseTimestamp: DateTime(2025, 8, 12, 10, 30),
      currency: 'PLN',
      totalGross: 12.50,
    );
    await tester.pumpWidget(
      _testApp(
        overrides: _baseOverrides(
          receipts: Stream.value([receipt]),
          monthlyTotals: Stream.value(const <MonthlyTotal>[]),
        ),
        child: const ReceiptsView(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(AppTestKeys.receiptList), findsOneWidget);
    expect(find.text('Test Store'), findsOneWidget);
  });
}

List<Override> _baseOverrides({
  required Stream<List<ReceiptRow>> receipts,
  required Stream<List<MonthlyTotal>> monthlyTotals,
}) {
  return [
    filteredReceiptsProvider.overrideWith((ref) => receipts),
    monthlyTotalsProvider.overrideWith((ref) => monthlyTotals),
    receiptsSearchQueryProvider.overrideWith((ref) => ''),
    receiptsFilterMonthProvider.overrideWith((ref) => null),
    receiptsAmountRangeProvider.overrideWith(
      (ref) => AmountRange.receiptFilterDefault,
    ),
  ];
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
