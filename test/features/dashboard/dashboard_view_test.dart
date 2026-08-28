import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/domain/models/dashboard_kpis.dart';
import 'package:receipts/domain/models/month_overview.dart';
import 'package:receipts/domain/models/monthly_total.dart';
import 'package:receipts/features/dashboard/dashboard_view.dart';
import 'package:receipts/l10n/app_localizations.dart';

void main() {
  testWidgets('DashboardView renders loading state', (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          selectedMonthProvider.overrideWith((ref) => DateTime(2025, 8)),
          monthlyTotalsProvider.overrideWith((ref) => Stream.empty()),
          dashboardKpisProvider.overrideWith((ref) async => _emptyKpis),
          monthOverviewProvider.overrideWith((ref, month) async {
            return _emptyOverview(month);
          }),
        ],
        child: const DashboardView(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

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

  testWidgets('DashboardView renders an error state', (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          selectedMonthProvider.overrideWith((ref) => DateTime(2025, 8)),
          monthlyTotalsProvider.overrideWith(
            (ref) => Stream.error(StateError('dashboard unavailable')),
          ),
          dashboardKpisProvider.overrideWith((ref) async => _emptyKpis),
          monthOverviewProvider.overrideWith((ref, month) async {
            return _emptyOverview(month);
          }),
        ],
        child: const DashboardView(),
      ),
    );
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('DashboardView renders populated dashboard data', (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          selectedMonthProvider.overrideWith((ref) => DateTime(2025, 8)),
          monthlyTotalsProvider.overrideWith(
            (ref) => Stream.value(
              const [MonthlyTotal(year: 2025, month: 8, total: 125.50)],
            ),
          ),
          dashboardKpisProvider.overrideWith((ref) async {
            return const DashboardKpis(
              totalLast30Days: 125.50,
              averageReceipt: 62.75,
              receiptsCount: 2,
            );
          }),
          monthOverviewProvider.overrideWith((ref, month) async {
            return MonthOverview(
              month: month,
              total: 125.50,
              receiptsCount: 2,
              averageReceipt: 62.75,
              maxReceipt: null,
              topCategories: const [
                CategoryBreakdown(
                  categoryId: 'dairy_eggs_bakery',
                  amount: 80,
                ),
              ],
            );
          }),
        ],
        child: const DashboardView(),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('chart_view')), findsOneWidget);
    expect(find.text('All data is processed on device'), findsOneWidget);
    expect(find.text('Dairy, Eggs & Bakery'), findsOneWidget);
  });

  testWidgets('DashboardView defers a missing selected-month correction', (
    tester,
  ) async {
    late WidgetRef widgetRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectedMonthProvider.overrideWith((ref) => DateTime(2025, 7)),
          monthlyTotalsProvider.overrideWith(
            (ref) => Stream.value(
              const [MonthlyTotal(year: 2025, month: 8, total: 125.50)],
            ),
          ),
          dashboardKpisProvider.overrideWith((ref) async => _emptyKpis),
          monthOverviewProvider.overrideWith((ref, month) async {
            return _emptyOverview(month);
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              widgetRef = ref;
              return const DashboardView();
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(widgetRef.read(selectedMonthProvider), DateTime(2025, 8));
    expect(tester.takeException(), isNull);
  });
}

const _emptyKpis = DashboardKpis(
  totalLast30Days: 0,
  averageReceipt: 0,
  receiptsCount: 0,
);

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
