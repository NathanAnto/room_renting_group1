// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:room_renting_group1/features/profile/state/profile_providers.dart';

import 'edit_profile_screen.dart'; 

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsyncValue = ref.watch(userProfileProvider);

    return Scaffold(
      // ✅ Correction n°1 : Utilisation de l'AppBar standard de Material
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: ShadTheme.of(context).colorScheme.background,
        elevation: 0,
      ),
      body: profileAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Profil non trouvé. Veuillez vous connecter.'));
          }
          
          return Container(
            padding: const EdgeInsets.all(24.0),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✅ Correction n°2 : Dimensionner l'avatar avec un SizedBox
                SizedBox(
                  width: 96,
                  height: 96,
                  child: ShadAvatar(
                    user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                    placeholder: Text(
                      user.displayName.substring(0, 2).toUpperCase(),
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(user.displayName, style: ShadTheme.of(context).textTheme.h2),
                const SizedBox(height: 4),
                Text(user.email, style: ShadTheme.of(context).textTheme.muted),
                const SizedBox(height: 32),
                
                ShadButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(user: user),
                      ),
                    );
                  },
                  child: const Text('Modifier le profil'),
                  width: double.infinity,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}