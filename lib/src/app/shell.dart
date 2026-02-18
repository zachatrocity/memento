import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _locationToIndex(String location) {
    if (location.startsWith(const SettingsRoute().location)) return 1;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(const HomeRoute().location);
        break;
      case 1:
        context.go(const SettingsRoute().location);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _locationToIndex(GoRouterState.of(context).uri.toString());

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.list), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
