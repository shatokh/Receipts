import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/domain/models/month_overview.dart';
import 'package:receipts/domain/models/monthly_total.dart';
import 'package:receipts/domain/models/receipt_row.dart';
import 'package:receipts/features/month/month_view.dart';
import 'package:receipts/l10n/app_localizations.dart';

void main() {
  testWidgets('MonthView renders loading states', (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          selectedMonthProvider.overrideWith((ref) => DateTime(2025, 8)),
          monthlyTotalsProvider.overrideWith((ref) => Stream.empty()),
          monthOverviewProvider.overrideWith(
            (ref, month) => Future.value(_emptyOverview(month)),
          ),
          receiptsByMonthProvider.overrideWith((ref, month) => Stream.empty()),
        ],
        child: const MonthView(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
  });

  testWidgets('MonthView renders empty month state', (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          selectedMonthProvider.overrideWith((ref) => DateTime(2025, 8)),
          monthlyTotalsProvider.overrideWith((ref) => Stream.value(const [])),
          monthOverviewProvider.overrideWith((ref, month) async {
            return MonthOverview(
              month: DateTime(month.year, month.month),
              total: 0,
              receiptsCount: 0,
              averageReceipt: 0,
              maxReceipt: null,
              topCategories: const [],
            );
          }),
          receiptsByMonthProvider.overrideWith((ref, month) {
            return Stream.value(const []);
          }),
        ],
        child: const MonthView(),
      ),
    );

    await tester.pump();

    expect(find.text('Month overview'), findsOneWidget);
    expect(
        find.text('No receipts recorded for this month yet'), findsOneWidget);
  });

  testWidgets('MonthView renders overview and receipt errors', (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          selectedMonthProvider.overrideWith((ref) => DateTime(2025, 8)),
          monthlyTotalsProvider.overrideWith(
            (ref) => Stream.value(const <MonthlyTotal>[]),
          ),
          monthOverviewProvider.overrideWith(
            (ref, month) => Future.error(StateError('overview unavailable')),
          ),
          receiptsByMonthProvider.overrideWith(
            (ref, month) => Stream.error(StateError('receipts unavailable')),
          ),
        ],
        child: const MonthView(),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Unable to load categories:'), findsOneWidget);
    expect(find.textContaining('Unable to load receipts:'), findsOneWidget);
  });

  testWidgets('MonthView renders populated month data', (tester) async {
    final receipt = ReceiptRow(
      id: 'receipt-1',
      merchantId: 'merchant-1',
      merchantName: 'Test Store',
      purchaseTimestamp: DateTime(2025, 8, 12, 10, 30),
      currency: 'PLN',
      totalGross: 125.50,
    );
    await tester.pumpWidget(
      _testApp(
        overrides: [
          selectedMonthProvider.overrideWith((ref) => DateTime(2025, 8)),
          monthlyTotalsProvider.overrideWith(
            (ref) => Stream.value(
              const [MonthlyTotal(year: 2025, month: 8, total: 125.50)],
            ),
          ),
          monthOverviewProvider.overrideWith((ref, month) async {
            return MonthOverview(
              month: month,
              total: 125.50,
              receiptsCount: 1,
              averageReceipt: 125.50,
              maxReceipt: receipt,
              topCategories: const [
                CategoryBreakdown(
                  categoryId: 'dairy_eggs_bakery',
                  amount: 125.50,
                ),
              ],
            );
          }),
          receiptsByMonthProvider.overrideWith(
            (ref, month) => Stream.value([receipt]),
          ),
        ],
        child: const MonthView(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Test Store'), findsOneWidget);
    expect(find.text('Dairy, Eggs & Bakery'), findsOneWidget);
  });
}

MonthOverview _emptyOverview(DateTime month) {
  return MonthOverview(
    month: month,
    total: 0,
    receiptsCount: 0,
    averageReceipt: 0,
    maxReceipt: null,
    topCategories: const [],
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
