// lib/features/profile/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/services/app_info_service.dart';
import '../../../core/utils/launch_url.dart';

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

class AboutScreen extends StatefulWidget {
  static const route = '/about';
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    AppInfoService.instance.packageInfo.then((pi) {
      if (mounted) setState(() => _info = pi);
    });
  }

  @override
  Widget build(BuildContext context) {
    final version =
        _info == null ? '...' : '${_info!.version}+${_info!.buildNumber}';

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
                    'About',
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
                    onPressed: () => context.pop(),
                  ),
                ),
              ];
            },
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildHeader(context, version),
                const SizedBox(height: 16),
                _buildDescriptionSection(context),
                _buildTeamSection(context),
                _buildLinksSection(context, version),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String version) {
    return Column(
      children: [
        const Text(
          'G1',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: darkTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Version $version',
          style: const TextStyle(fontSize: 16, color: lightTextColor),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    return _buildSection(
      title: 'About the App',
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'This platform facilitates connections for HES-SO students, making it easy to find either a room or a tenant during academic exchanges. The goal is to develop a cross-platform mobile application in data engineering and analytics, integrating various data sources to provide a seamless user experience.',
          textAlign: TextAlign.justify,
          style: TextStyle(
            color: darkTextColor,
            height: 1.5,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSection(BuildContext context) {
    final teamMembers = [
      {'name': 'Nathan Antonietti', 'github': 'https://github.com/NathanAnto'},
      {'name': 'Loïc Christen', 'github': 'https://github.com/NotDonaldPump'},
      {'name': 'Vincent Cordola', 'github': 'https://github.com/VinceCor'},
      {'name': 'Jeremy Duc', 'github': 'https://github.com/jijiduc'},
    ];

    return _buildSection(
      title: 'Development Team',
      items: teamMembers.map((member) {
        return _SettingsItem(
          icon: Icons.person_outline,
          title: member['name']!,
          subtitle: 'View GitHub profile',
          onTap: () => safeLaunchUrl(member['github']!),
        );
      }).toList(),
    );
  }

  Widget _buildLinksSection(BuildContext context, String version) {
    final links = [
      _SettingsItem(
        icon: Icons.code,
        title: 'GitHub Repository',
        subtitle: 'See the source code',
        onTap: () => safeLaunchUrl(AppInfo.repoUrl),
      ),
      _SettingsItem(
        icon: Icons.privacy_tip_outlined,
        title: 'Privacy Policy',
        subtitle: 'Read our privacy policy',
        onTap: () => context.push('/privacy-policy'),
      ),
      _SettingsItem(
        icon: Icons.description_outlined,
        title: 'Terms of Service',
        subtitle: 'Read our terms of service',
        onTap: () => context.push('/terms-of-service'),
      ),
      _SettingsItem(
        icon: Icons.article_outlined,
        title: 'Licenses',
        subtitle: 'View open-source packages',
        onTap: () => showLicensePage(
          context: context,
          applicationName: 'G1',
          applicationVersion: version,
        ),
      ),
    ];

    return _buildSection(title: 'Links', items: links);
  }
}

// --- Widgets et Classes Helper Réutilisables ---

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

Widget _buildSection({
  required String title,
  List<_SettingsItem> items = const [],
  Widget? child,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12, top: 16),
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
        child: child ??
            Column(
              children: items.asMap().entries.map((entry) {
                final isLast = entry.key == items.length - 1;
                return Column(
                  children: [
                    _buildSettingsTile(entry.value),
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
      const SizedBox(height: 8),
    ],
  );
}

Widget _buildSettingsTile(_SettingsItem item) {
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