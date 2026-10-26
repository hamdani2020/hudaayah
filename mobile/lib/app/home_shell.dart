import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';

/// Persistent bottom-navigation shell for the four main destinations
/// (Home · Read · Learn · Profile), matching the Stitch bottom nav
/// (design-mapping §2 / §6.1). The bar is a translucent `surface` (95%) with a
/// top hairline border; the selected item renders `primary` + semibold.
/// Each tab keeps its own navigation state via StatefulShellRoute.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: 'Read',
    ),
    NavigationDestination(
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school),
      label: 'Learn',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  void _onTap(int index) {
    // Tapping the active tab pops it to its root; otherwise switch branch.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.outlineVariant),
          ),
        ),
        child: NavigationBar(
          backgroundColor: AppTheme.surface.withValues(alpha: 0.95),
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          destinations: _destinations,
        ),
      ),
    );
  }
}
