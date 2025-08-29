// lib/features/profile/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:room_renting_group1/features/profile/state/profile_providers.dart';
import 'package:room_renting_group1/core/models/user_model.dart'; // pour UserRole

class SettingsScreen extends ConsumerWidget {
  static const route = '/settings';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur: $e')),
        data: (user) {
          // On peut afficher la page même si user == null (compte nouvellement créé),
          // mais la section Admin sera cachée.
          final isAdmin = _isAdmin(user);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- Account ---
              ShadCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'Account'),
                    _tile(
                      context: context,
                      icon: Icons.person_outline,
                      title: 'Profil',
                      subtitle: user?.displayName ?? 'Voir/éditer vos informations',
                      onTap: () => context.push('/profile'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- General ---
              ShadCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'General'),
                    _tile(
                      context: context,
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'Infos app, équipe, licences',
                      onTap: () => context.push('/about'),
                    ),
                    const Divider(),
                    _tile(
                      context: context,
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      subtitle: 'Préférences à venir',
                      onTap: () {},
                    ),
                    const Divider(),
                    _tile(
                      context: context,
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'Consulter la politique de confidentialité',
                      onTap: () {
                        // TODO: ouvrir un lien si vous en avez un (url_launcher)
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- Support ---
              ShadCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'Support'),
                    _tile(
                      context: context,
                      icon: Icons.bug_report_outlined,
                      title: 'Signaler un bug',
                      subtitle: 'Dites-nous ce qui cloche',
                      onTap: () {
                        // TODO: ouvrir un formulaire / email
                      },
                    ),
                    const Divider(),
                    _tile(
                      context: context,
                      icon: Icons.feedback_outlined,
                      title: 'Feedback',
                      subtitle: 'Vos idées nous intéressent',
                      onTap: () {
                        // TODO: ouvrir un formulaire / email
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- Admin (visible uniquement si admin) ---
              if (isAdmin) ...[
                ShadCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, 'Admin'),
                      _tile(
                        context: context,
                        icon: Icons.group_outlined,
                        title: 'Utilisateurs',
                        subtitle: 'Voir la liste des utilisateurs',
                        onTap: () => context.push('/admin/users'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // --- Sign out ---
              ShadButton(
                width: double.infinity,
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                child: const Text('Se déconnecter'),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isAdmin(UserModel? user) {
    if (user == null) return false;

    // 1) Cas enum UserRole.admin
    if (user.role == UserRole.admin) return true;

    // 2) Sécurité : si pour une raison X le rôle est stocké sous forme de string directe
    // (ex. mapping incomplet), on tolère la valeur brute 'admin'
    final raw = user.role.name.toLowerCase();
    return raw == 'admin';
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(text, style: theme.textTheme.muted.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _tile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = ShadTheme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.small),
      subtitle: Text(subtitle, style: theme.textTheme.p),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
