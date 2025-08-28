// Fichier : lib/auth_gate.dart (Version améliorée et plus robuste)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:room_renting_group1/features/authentication/screens/login_screen.dart'; 
import 'package:room_renting_group1/features/profile/screens/create_profile_screen.dart';
import 'package:room_renting_group1/main_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginScreen(); 
        }

        return FutureBuilder<DocumentSnapshot>(
          // La requête reste la même
          future: FirebaseFirestore.instance.collection('Profile').doc(snapshot.data!.uid).get(),
          builder: (context, profileSnapshot) {
            
            // --- NOUVEAU : Gestion de l'état d'erreur ---
            if (profileSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text("Erreur lors du chargement du profil: ${profileSnapshot.error}"),
                ),
              );
            }

            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // --- NOUVEAU : Vérification plus sûre ---
            // On vérifie si la snapshot a des données ET si le document existe
            if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
              // L'utilisateur a un profil, on affiche l'application
              return const MainShell();
            } else {
              // L'utilisateur n'a pas de profil, on redirige vers sa création
              return const CreateProfileScreen();
            }
          },
        );
      },
    );
  }
}