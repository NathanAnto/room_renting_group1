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
      body: profileAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Profil non trouvé.'));
          }
          
          return Container(
            padding: const EdgeInsets.all(24.0),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: ShadTheme.of(context).colorScheme.muted,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.displayName.substring(0, 2).toUpperCase(),
                          style: const TextStyle(fontSize: 40),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                
                Text(user.displayName, style: ShadTheme.of(context).textTheme.h2),
                const SizedBox(height: 4),
                Text(user.email, style: ShadTheme.of(context).textTheme.muted),
                const SizedBox(height: 32),
                
                ShadButton(
                // ✅ 1. Rendez la fonction onPressed "async"
                onPressed: () async {
                  // ✅ 2. Attendez que l'écran d'édition se ferme avec "await"
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(user: user),
                    ),
                  );

                  // ✅ 3. Une fois de retour, rafraîchissez les données
                  ref.invalidate(userProfileProvider);
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