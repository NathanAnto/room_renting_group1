// lib/features/profile/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:room_renting_group1/features/profile/state/profile_providers.dart';
import 'package:room_renting_group1/core/models/user_model.dart';

// --- Theme colors matching dashboard design ---
const Color primaryBlue = Color(0xFF0D47A1);
const Color lightGreyBackground = Color(0xFFF8F9FA);
const Color darkTextColor = Color(0xFF343A40);
const Color lightTextColor = Color(0xFF6C757D);

// Class helper to hide scrollbar
class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class SettingsScreen extends ConsumerWidget {
  static const route = '/settings';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: lightGreyBackground,
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: _NoScrollbarBehavior(),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  title: const Text(
                    'Settings',
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  centerTitle: true,
                  pinned: true,
                  backgroundColor: lightGreyBackground,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: primaryBlue),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ];
            },
            body: profileAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: primaryBlue),
              ),
              error: (e, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: lightTextColor),
                    const SizedBox(height: 16),
                    Text('Something went wrong',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkTextColor)),
                    const SizedBox(height: 8),
                    Text('$e',
                        style: const TextStyle(color: lightTextColor)),
                  ],
                ),
              ),
              data: (user) => _buildSettingsContent(context, user),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context, UserModel? user) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // General Settings Section
        _buildSection(
          context: context,
          title: 'General',
          items: [
            _SettingsItem(
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'App info, team, and licenses',
              onTap: () => context.push('/about'),
            ),
          ],
        ),
        // Bottom spacing
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
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
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  _buildSettingsTile(context, item),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: 60,
                      color: Color(0xFFE9ECEF),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSettingsTile(BuildContext context, _SettingsItem item) {
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
        item.title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: darkTextColor,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        item.subtitle,
        style: const TextStyle(
          color: lightTextColor,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: lightTextColor,
        size: 20,
      ),
      onTap: item.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}