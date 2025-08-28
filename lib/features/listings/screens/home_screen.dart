import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Pour le bouton de déconnexion

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              // GoRouter gérera la redirection automatiquement
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Bienvenue ! Vous êtes connecté.'),
      ),
    );
  }
}