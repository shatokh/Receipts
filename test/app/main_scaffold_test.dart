import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:receipts/app/app_test_keys.dart';
import 'package:receipts/app/main_scaffold.dart';
import 'package:receipts/l10n/app_localizations.dart';

void main() {
  testWidgets('MainScaffold exposes Maestro navigation semantics',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainScaffold(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const Scaffold(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pump();

    for (final identifier in [
      AppTestSemanticsIds.navMonth,
      AppTestSemanticsIds.navReceipts,
    ]) {
      final finder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.identifier == identifier,
      );

      expect(tester.getSemantics(finder).identifier, identifier);
    }
  });
}
