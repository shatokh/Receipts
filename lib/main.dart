import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:biedronka_expenses/theme.dart';
import 'package:biedronka_expenses/app/router.dart';
import 'package:biedronka_expenses/data/database.dart';

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
  
  // Initialize Sentry if DSN is available (disabled by default)
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.debug = false;
      },
      appRunner: () => runApp(const ProviderScope(child: BiedronkaExpensesApp())),
    );
  } else {
    runApp(const ProviderScope(child: BiedronkaExpensesApp()));
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
