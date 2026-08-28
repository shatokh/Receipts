import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:receipts/app/app_test_keys.dart';

import '../l10n/app_localizations.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onTap(context, index),
        items: _buildItems(context),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildItems(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home, key: AppTestKeys.navHome),
        label: localizations.navHome,
      ),
      BottomNavigationBarItem(
        icon: Semantics(
          container: true,
          identifier: AppTestSemanticsIds.navImport,
          child: const Icon(Icons.upload_file, key: AppTestKeys.navImport),
        ),
        label: localizations.navImport,
      ),
      BottomNavigationBarItem(
        icon: Semantics(
          container: true,
          identifier: AppTestSemanticsIds.navMonth,
          child: const Icon(Icons.bar_chart, key: AppTestKeys.navStats),
        ),
        label: localizations.navStats,
      ),
      BottomNavigationBarItem(
        icon: Semantics(
          container: true,
          identifier: AppTestSemanticsIds.navReceipts,
          child: const Icon(Icons.receipt_long, key: AppTestKeys.navReceipts),
        ),
        label: localizations.navReceipts,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.settings, key: AppTestKeys.navSettings),
        label: localizations.navSettings,
      ),
    ];
  }

  int _getCurrentIndex(BuildContext context) {
    final location =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    switch (location) {
      case '/dashboard':
        return 0;
      case '/import':
        return 1;
      case '/month':
        return 2;
      case '/receipts':
        return 3;
      case '/settings':
        return 4;
      default:
        return 0;
    }
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/import');
        break;
      case 2:
        context.go('/month');
        break;
      case 3:
        context.go('/receipts');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }
}
