// lib/features/profile/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/services/app_info_service.dart';
import '../../../core/utils/launch_url.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';


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
    final version = _info == null ? '...' : '${_info!.version}+${_info!.buildNumber}';
    const primaryBlue = Color(0xFF0D47A1);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, version),
                  const SizedBox(height: 24),
                  _buildDescriptionCard(context),
                  const SizedBox(height: 24),
                  _buildTeamCard(context),
                  const SizedBox(height: 24),
                  _buildLinksCard(context, version, primaryBlue),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String version) {
    return Column(
      children: [
        Text(
          'G1',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Version $version',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
  
  Widget _buildDescriptionCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'This platform facilitates connections for HES-SO students, making it easy to find either a room or a tenant during academic exchanges. The goal is to develop a cross-platform mobile application in data engineering and analytics, integrating various data sources to provide a seamless user experience.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[800],
                height: 1.5,
              ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context) {
    final teamMembers = [
      {'name': 'Nathan Antonietti', 'github': 'https://github.com/NathanAnto'},
      {'name': 'Loïc Christen', 'github': 'https://github.com/NotDonaldPump'},
      {'name': 'Vincent Cordola', 'github': 'https://github.com/VinceCor'},
      {'name': 'Jeremy Duc', 'github': 'https://github.com/jijiduc'},
    ];

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
              'Development Team',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D47A1),
                  ),
            ),
            const SizedBox(height: 8),
            ...teamMembers.map((member) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person_outline, color: Colors.grey[500]),
                  title: Text(member['name']!, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                  trailing: Icon(Icons.link, color: Colors.grey[400], size: 20),
                  onTap: () => safeLaunchUrl(member['github']!),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksCard(BuildContext context, String version, Color primaryColor) {
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
              'Links',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            _buildLinkTile(
              icon: Icons.code,
              title: 'GitHub Repository',
              onTap: () => safeLaunchUrl(AppInfo.repoUrl),
            ),
            const Divider(),
            _buildLinkTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () => context.push(PrivacyPolicyScreen.route),
            ),
            const Divider(),
            _buildLinkTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () => context.push(TermsOfServiceScreen.route),
            ),
            const Divider(),
            _buildLinkTile(
              icon: Icons.article_outlined,
              title: 'Licenses',
              subtitle: 'View open-source packages',
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'G1',
                applicationVersion: version,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.grey[500]),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey[600])) : null,
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}
