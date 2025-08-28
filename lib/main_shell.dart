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
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Logements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: 'Profil',
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
    if (location.startsWith('/profile')) {
      return 1;
    }
    // Par défaut, c'est l'accueil
    return 0;
  }
 
  // Fonction pour naviguer lorsque l'on clique sur un onglet
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/profile');
        break;
    }
  }
}