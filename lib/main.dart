import 'package:flutter/material.dart';
import 'package:receipts/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'package:receipts/app/providers.dart';
import 'package:receipts/app/router.dart';
import 'package:receipts/core/localization/locale_controller.dart';
import 'package:receipts/data/database.dart';
import 'package:receipts/data/repositories/settings_repository.dart';
import 'package:receipts/theme.dart';

// Workmanager callback for background tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Background receipt processing could go here
    return Future.value(true);
  });
}

Widget buildApp({List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: const ReceiptsApp(),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseHelper.database;

  // Initialize Workmanager for background tasks
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  final sharedPreferences = await SharedPreferences.getInstance();
  final settingsRepository = SettingsRepository(sharedPreferences);
  final sentryEnabled = settingsRepository.isSentryEnabled();
  final devLoggingEnabled = settingsRepository.isDevLoggingEnabled();

  final baseOverrides = <Override>[
    settingsRepositoryProvider.overrideWithValue(settingsRepository),
    sentryEnabledProvider.overrideWith((ref) {
      return SentryEnabledNotifier(settingsRepository, sentryEnabled);
    }),
    devLoggingEnabledProvider.overrideWith((ref) {
      return DevLoggingEnabledNotifier(
        settingsRepository,
        devLoggingEnabled,
      );
    }),
  ];

  void runAppWithProviders() {
    runApp(buildApp(overrides: baseOverrides));
  }

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  if (sentryEnabled && sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.debug = false;
      },
      appRunner: runAppWithProviders,
    );
  } else {
    runAppWithProviders();
  }
}

class ReceiptsApp extends ConsumerWidget {
  const ReceiptsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
    );
  }
}
