import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/features/receipts/receipts_view.dart';
import 'package:receipts/l10n/app_localizations.dart';

void main() {
  testWidgets('ReceiptsView renders empty receipts state', (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          filteredReceiptsProvider
              .overrideWith((ref) => Stream.value(const [])),
          monthlyTotalsProvider.overrideWith((ref) => Stream.value(const [])),
          receiptsSearchQueryProvider.overrideWith((ref) => ''),
          receiptsFilterMonthProvider.overrideWith((ref) => null),
          receiptsAmountRangeProvider.overrideWith(
            (ref) => const RangeValues(0, 1000),
          ),
        ],
        child: const ReceiptsView(),
      ),
    );

    await tester.pump();

    expect(find.text('Receipts'), findsOneWidget);
    expect(find.text('No receipts found'), findsOneWidget);
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
