import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, key: ValueKey('nav_home')),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file, key: ValueKey('nav_import')),
            label: 'Import',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart, key: ValueKey('nav_stats')),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long, key: ValueKey('nav_receipts')),
            label: 'Receipts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, key: ValueKey('nav_settings')),
            label: 'Settings',
          ),
        ],
      ),
    );
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
