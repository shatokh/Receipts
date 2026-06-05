import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/domain/models/dashboard_kpis.dart';
import 'package:receipts/domain/models/month_overview.dart';
import 'package:receipts/features/dashboard/dashboard_view.dart';
import 'package:receipts/l10n/app_localizations.dart';

void main() {
  testWidgets('DashboardView renders empty dashboard state', (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          selectedMonthProvider.overrideWith((ref) => DateTime(2025, 8)),
          monthlyTotalsProvider.overrideWith((ref) => Stream.value(const [])),
          dashboardKpisProvider.overrideWith((ref) async {
            return const DashboardKpis(
              totalLast30Days: 0,
              averageReceipt: 0,
              receiptsCount: 0,
            );
          }),
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
        ],
        child: const DashboardView(),
      ),
    );

    await tester.pump();

    expect(find.text('Spending dashboard'), findsOneWidget);
    expect(find.text('No receipts yet'), findsOneWidget);
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
