// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:room_renting_group1/core/models/user_model.dart'; // Import pour UserRole
import 'package:room_renting_group1/features/profile/state/profile_providers.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final profileAsyncValue = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Paramètres',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: profileAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Profil non trouvé.'));
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- CARTE D'INFORMATIONS PRINCIPALES ---
                    ShadCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.colorScheme.muted,
                            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: (user.photoUrl == null || user.photoUrl!.isEmpty) && user.displayName.isNotEmpty
                                ? Text(
                                    user.displayName.substring(0, 2).toUpperCase(),
                                    style: theme.textTheme.h1.copyWith(color: theme.colorScheme.primary),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(user.displayName, style: theme.textTheme.h2, textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(user.email, style: theme.textTheme.muted, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- CARTE DES DÉTAILS DU PROFIL ---
                    ShadCard(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          _buildInfoTile(
                            context: context,
                            icon: Icons.flag_outlined,
                            title: 'Pays',
                            subtitle: user.country ?? 'Non spécifié',
                          ),
                          const Divider(),
                          _buildInfoTile(
                            context: context,
                            icon: Icons.phone_outlined,
                            title: 'Téléphone',
                            subtitle: user.phone != null && user.phone!.isNotEmpty
                                ? user.phone!
                                : 'Non spécifié',
                          ),
                          const Divider(),
                          _buildInfoTile(
                            context: context,
                            icon: Icons.badge_outlined,
                            title: 'Compte',
                            subtitle: user.role.name[0].toUpperCase() + user.role.name.substring(1),
                          ),
                          if (user.role == UserRole.student) ...[
                            const Divider(),
                            _buildInfoTile(
                              context: context,
                              icon: Icons.school_outlined,
                              title: 'École',
                              subtitle: user.school != null && user.school!.isNotEmpty
                                  ? user.school!
                                  : 'Non spécifiée',
                            ),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- BOUTON MODIFIER ---
                    ShadButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(user: user),
                          ),
                        );
                        ref.invalidate(userProfileProvider);
                      },
                      width: double.infinity,
                      child: const Text('Modifier le profil'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Widget helper pour créer une ligne d'information stylisée.
  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = ShadTheme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary, size: 24),
      title: Text(title, style: theme.textTheme.small, textAlign: TextAlign.start),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
