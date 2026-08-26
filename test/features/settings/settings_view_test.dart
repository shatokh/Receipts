import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/core/localization/locale_controller.dart';
import 'package:receipts/data/repositories/settings_repository.dart';
import 'package:receipts/features/settings/settings_view.dart';
import 'package:receipts/features/settings/language_page.dart';
import 'package:receipts/features/settings/widgets/debug_settings_section.dart';
import 'package:receipts/l10n/app_localizations.dart';

void main() {
  testWidgets('LanguagePage updates the selected locale', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = LocaleController();

    await tester.pumpWidget(
      _testApp(
        overrides: [
          localeProvider.overrideWith((ref) => controller),
        ],
        child: const LanguagePage(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Polish'));
    await tester.pump();

    expect(controller.state, const Locale('pl'));
  });

  testWidgets('SettingsView renders main settings sections', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = SettingsRepository(
      await SharedPreferences.getInstance(),
    );

    await tester.pumpWidget(
      _testApp(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          sentryEnabledProvider.overrideWith(
            (ref) => SentryEnabledNotifier(repository, false),
          ),
          devLoggingEnabledProvider.overrideWith(
            (ref) => DevLoggingEnabledNotifier(repository, false),
          ),
          errorLogPathProvider.overrideWith((ref) async {
            return 'receipts-import-errors.jsonl';
          }),
          localeProvider.overrideWith((ref) => LocaleController()),
        ],
        child: const SettingsView(),
      ),
    );

    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsWidgets);
    expect(find.text('Crash reports'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();

    expect(find.text('Debug'), findsOneWidget);
  });

  testWidgets('DebugSettingsSection confirms before clearing receipt data',
      (tester) async {
    var clearCalls = 0;
    await tester.pumpWidget(
      _testApp(
        overrides: const [],
        child: Scaffold(
          body: DebugSettingsSection(
            devLoggingEnabled: false,
            logPath: const AsyncValue.data('receipts-import-errors.jsonl'),
            onClearReceiptData: () async {
              clearCalls++;
            },
            onDevLoggingChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Clear all data'));
    await tester.pumpAndSettle();

    expect(find.text('Clear all data?'), findsOneWidget);
    expect(
      find.text(
        'This will permanently delete all receipts and spending statistics. App settings will be kept. This action cannot be undone.',
      ),
      findsOneWidget,
    );
    expect(clearCalls, 0);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(clearCalls, 0);

    await tester.tap(find.text('Clear all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pump();

    expect(clearCalls, 1);
    expect(find.text('Receipt data cleared'), findsOneWidget);
  });

  testWidgets('DebugSettingsSection shows a safe cleanup failure message',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: const [],
        child: Scaffold(
          body: DebugSettingsSection(
            devLoggingEnabled: false,
            logPath: const AsyncValue.data('receipts-import-errors.jsonl'),
            onClearReceiptData: () async => throw StateError('raw receipt data'),
            onDevLoggingChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Clear all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pump();

    expect(find.text('Could not clear receipt data. Try again.'), findsOneWidget);
    expect(find.text('raw receipt data'), findsNothing);
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
