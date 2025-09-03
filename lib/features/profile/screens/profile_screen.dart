// lib/features/profile/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for logout functionality

// --- Imports to be adapted to your project ---
import 'package:room_renting_group1/core/models/user_model.dart';
import 'package:room_renting_group1/features/profile/state/profile_providers.dart';
import 'edit_profile_screen.dart'; // Make sure this screen exists

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsyncValue = ref.watch(userProfileProvider);
    final lightGreyBackground = Colors.grey[200];

    return Scaffold(
      backgroundColor: lightGreyBackground,
      appBar: AppBar(
        // MODIFICATION: Title removed for a cleaner look.
        backgroundColor: lightGreyBackground,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (user) {
            if (user == null) {
              return const Center(child: Text('Profile not found.'));
            }

            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        _buildUserInfo(context, user),
                        const SizedBox(height: 32),
                        // MODIFICATION: Button positions swapped
                        _buildLogoutButton(context),
                        const SizedBox(height: 24),
                        _buildDetailsCard(context, user),
                        const SizedBox(height: 24),
                        _buildEditProfileButton(context, user, ref),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Displays the user's avatar, name, and email.
  Widget _buildUserInfo(BuildContext context, UserModel user) {
    const primaryBlue = Color(0xFF0D47A1);
    final textTheme = Theme.of(context).textTheme;

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
            child: (user.photoUrl == null || user.photoUrl!.isEmpty) && user.displayName.isNotEmpty
                ? Text(
                    user.displayName.substring(0, 2).toUpperCase(),
                    style: textTheme.headlineLarge?.copyWith(
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
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  /// A single, centered button to edit the profile.
  Widget _buildEditProfileButton(BuildContext context, UserModel user, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(user: user),
          ),
        ).then((_) {
          ref.invalidate(userProfileProvider);
        });
      },
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: const Text('Edit Profile'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Card containing detailed user information.
  Widget _buildDetailsCard(BuildContext context, UserModel user) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.flag_outlined,
              title: 'Country',
              value: user.country ?? 'Not specified',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              title: 'Phone',
              value: user.phone != null && user.phone!.isNotEmpty
                  ? user.phone!
                  : 'Not specified',
            ),
            const Divider(height: 24),
            _buildInfoRow(
              icon: Icons.badge_outlined,
              title: 'Account Type',
              value: user.role.name[0].toUpperCase() + user.role.name.substring(1),
            ),
            if (user.role == UserRole.student) ...[
              const Divider(height: 24),
              _buildInfoRow(
                icon: Icons.school_outlined,
                title: 'School',
                value: user.school != null && user.school!.isNotEmpty
                    ? user.school!
                    : 'Not specified',
              ),
            ]
          ],
        ),
      ),
    );
  }
  
  /// A styled logout button.
  Widget _buildLogoutButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          context.go('/login');
        }
      },
      icon: const Icon(Icons.logout),
      label: const Text('Log Out'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red.shade700,
        side: BorderSide(color: Colors.red.shade200),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Helper widget for a single row of information in the details card.
  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[500], size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

