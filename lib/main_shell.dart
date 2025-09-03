// lib/main_shell.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0D47A1);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        // --- Style Updates ---
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue, // Active icon color
        unselectedItemColor: Colors.grey[500], // Inactive icon color
        showSelectedLabels: false, // Hide text labels
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed, // Ensures consistent layout
        elevation: 1.0, // Subtle shadow for depth

        // MODIFICATION: Set font sizes to 0 to completely remove the space
        // reserved for labels, making the bar more compact vertically.
        selectedFontSize: 0,
        unselectedFontSize: 0,

        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard', // Label is kept for semantics
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location.startsWith('/dashboard')) {
      return 0;
    }
    if (location == '/') {
      return 1;
    }
    if (location.startsWith('/profile')) {
      return 2;
    }
    // Default to 'Explore' tab
    return 1;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }
}

