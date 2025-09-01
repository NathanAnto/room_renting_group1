// lib/main_shell.dart (Mis à jour)
 
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child; // Le widget enfant (la page actuelle) fourni par GoRouter

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Le corps de la page est maintenant l'enfant fourni par le routeur
      body: child,
     
      // La barre de navigation en bas
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
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
        // Calcule l'index actuel en fonction de la route
        currentIndex: _calculateSelectedIndex(context),
        // La navigation est maintenant gérée par GoRouter
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
 
  // Fonction pour déterminer quel onglet est actif en fonction de l'URL
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
    // Par défaut, c'est l'accueil
    return 1;
  }
 
  // Fonction pour naviguer lorsque l'on clique sur un onglet
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