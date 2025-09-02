import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // 1. Importer go_router
import 'package:shadcn_ui/shadcn_ui.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bienvenue sur votre Dashboard !'),
            const SizedBox(height: 40),

            // 2. Ajouter le bouton de test
            // Ce bouton est temporaire et sert uniquement au développement.
            ShadButton(
              onPressed: () {
                // Utilise go_router pour naviguer vers la route que tu as définie
                context.go('/review-test');
              },
              child: const Text('Accéder à la Page de Test des Avis'),
            ),
          ],
        ),
      ),
    );
  }
}
