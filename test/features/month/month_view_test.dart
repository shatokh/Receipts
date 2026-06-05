import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/domain/models/month_overview.dart';
import 'package:receipts/features/month/month_view.dart';
import 'package:receipts/l10n/app_localizations.dart';

void main() {
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
