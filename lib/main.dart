import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'package:biedronka_expenses/app/providers.dart';
import 'package:biedronka_expenses/app/router.dart';
import 'package:biedronka_expenses/data/database.dart';
import 'package:biedronka_expenses/data/repositories/settings_repository.dart';
import 'package:biedronka_expenses/theme.dart';

// Workmanager callback for background tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Background receipt processing could go here
    return Future.value(true);
  });
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

  void runAppWithProviders() {
    runApp(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepository),
          sentryEnabledProvider.overrideWith((ref) {
            return SentryEnabledNotifier(settingsRepository, sentryEnabled);
          }),
        ],
        child: const BiedronkaExpensesApp(),
      ),
    );
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

class BiedronkaExpensesApp extends StatelessWidget {
  const BiedronkaExpensesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Biedronka Expenses',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: router,
    );
  }
}
