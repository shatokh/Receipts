import 'package:go_router/go_router.dart';
import 'package:receipts/features/onboarding/onboarding_view.dart';
import 'package:receipts/features/dashboard/dashboard_view.dart';
import 'package:receipts/features/month/month_view.dart';
import 'package:receipts/features/receipts/receipts_view.dart';
import 'package:receipts/features/receipt_details/receipt_details_view.dart';
import 'package:receipts/features/import/import_view.dart';
import 'package:receipts/features/settings/settings_view.dart';
import 'package:receipts/app/main_scaffold.dart';

final router = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingView(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardView(),
        ),
        GoRoute(
          path: '/month',
          builder: (context, state) => const MonthView(),
        ),
        GoRoute(
          path: '/receipts',
          builder: (context, state) => const ReceiptsView(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsView(),
        ),
        GoRoute(
          path: '/import',
          builder: (context, state) => const ImportView(),
        ),
      ],
    ),
    GoRoute(
      path: '/receipt/:id',
      builder: (context, state) => ReceiptDetailsView(
        receiptId: state.pathParameters['id']!,
      ),
    ),
  ],
);