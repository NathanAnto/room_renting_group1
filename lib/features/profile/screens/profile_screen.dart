// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

// --- Imports à adapter à votre projet ---
import 'package:room_renting_group1/core/models/user_model.dart';
import 'package:room_renting_group1/features/profile/state/profile_providers.dart';
import 'edit_profile_screen.dart';

// --- Thème de couleurs cohérent ---
const Color primaryBlue = Color(0xFF0D47A1);
const Color lightGreyBackground = Color(0xFFF8F9FA);
const Color darkTextColor = Color(0xFF343A40);
const Color lightTextColor = Color(0xFF6C757D);

// Class helper pour masquer la barre de défilement
class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsyncValue = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: lightGreyBackground,
      body: SafeArea(
        child: profileAsyncValue.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: primaryBlue)),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (user) {
            if (user == null) {
              return const Center(child: Text('Profile not found.'));
            }

            return ScrollConfiguration(
              behavior: _NoScrollbarBehavior(),
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      backgroundColor: lightGreyBackground,
                      elevation: 0,
                      pinned: true,
                      actions: [
                        ShadButton.ghost(
                          leading: const Icon(Icons.settings_outlined,
                              color: primaryBlue, size: 24),
                          onPressed: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ];
                },
                body: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    _buildUserInfo(context, user),
                    const SizedBox(height: 32),
                    _buildDetailsSection(context, user),
                    const SizedBox(height: 32),
                    _buildActionButtons(context, user, ref),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Affiche l'avatar, le nom et l'email de l'utilisateur.
  Widget _buildUserInfo(BuildContext context, UserModel user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor: primaryBlue.withOpacity(0.1),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? NetworkImage(user.photoUrl!)
                : null,
            child: (user.photoUrl == null || user.photoUrl!.isEmpty) &&
                    user.displayName.isNotEmpty
                ? Text(
                    user.displayName.substring(0, 2).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.displayName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: const TextStyle(fontSize: 16, color: lightTextColor),
        ),
      ],
    );
  }

  /// Section contenant les informations détaillées de l'utilisateur.
  Widget _buildDetailsSection(BuildContext context, UserModel user) {
    final details = [
      _DetailItem(
          icon: Icons.flag_outlined,
          title: 'Country',
          value: user.country ?? 'Not specified'),
      _DetailItem(
          icon: Icons.phone_outlined,
          title: 'Phone',
          value: user.phone?.isNotEmpty == true ? user.phone! : 'Not specified'),
      _DetailItem(
          icon: Icons.badge_outlined,
          title: 'Account Type',
          value: user.role.name[0].toUpperCase() + user.role.name.substring(1)),
      if (user.role == UserRole.student)
        _DetailItem(
            icon: Icons.school_outlined,
            title: 'School',
            value: user.school?.isNotEmpty == true ? user.school! : 'Not specified'),
    ];

    return _buildSection(
      title: 'Details',
      child: Column(
        children: details.asMap().entries.map((entry) {
          final isLast = entry.key == details.length - 1;
          return Column(
            children: [
              _buildDetailTile(entry.value),
              if (!isLast)
                const Divider(height: 1, indent: 60, color: Color(0xFFE9ECEF)),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Regroupe les boutons d'action (Modifier le profil, Déconnexion).
  Widget _buildActionButtons(BuildContext context, UserModel user, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ShadButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user: user),
                ),
              ).then((_) {
                ref.invalidate(userProfileProvider);
              });
            },
            leading: const Icon(Icons.edit_outlined, size: 18),
            child: const Text('Edit Profile'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ShadButton.destructive(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            leading: const Icon(Icons.logout, size: 18),
            child: const Text('Sign Out'),
          ),
        ),
      ],
    );
  }
}

// --- Widgets et Classes Helper Réutilisables ---

/// Classe de données pour un élément d'information.
class _DetailItem {
  final IconData icon;
  final String title;
  final String value;
  _DetailItem({required this.icon, required this.title, required this.value});
}

/// Construit une section générique avec un titre et un contenu.
Widget _buildSection({required String title, required Widget child}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkTextColor,
          ),
        ),
      ),
      ShadCard(
        backgroundColor: Colors.white,
        padding: EdgeInsets.zero,
        child: child,
      ),
    ],
  );
}

/// Construit une tuile pour afficher une information (icône, titre, valeur).
Widget _buildDetailTile(_DetailItem item) {
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(item.icon, color: primaryBlue, size: 20),
    ),
    title: Text(
      item.value, // La valeur est mise en avant
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: darkTextColor,
        fontSize: 16,
      ),
    ),
    subtitle: Text(
      item.title, // Le label est plus discret
      style: const TextStyle(
        color: lightTextColor,
        fontSize: 14,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  );
}