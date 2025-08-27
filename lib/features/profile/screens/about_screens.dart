// lib/features/profile/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/services/app_info_service.dart';
import '../../../core/utils/launch_url.dart';

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
    final version = _info == null ? '…' : '${_info!.version}+${_info!.buildNumber}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header style "shadcn-like": large title + muted subtitle
          Text(AppInfo.appName, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Version $version', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),

          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Application de location d'appartements.\n"
                "Projet HES (ingénierie de données) — Flutter + Firebase, reconnaissance faciale (DeepFace), et modèles de régression.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text('Équipe', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...AppInfo.team.map((m) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(m['name'] ?? ''),
                subtitle: Text(m['role'] ?? ''),
              )),

          const SizedBox(height: 16),
          Text('Liens', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link),
            title: const Text('Repository GitHub'),
            subtitle: Text(AppInfo.repoUrl),
            onTap: () => safeLaunchUrl(AppInfo.repoUrl),
            trailing: const Icon(Icons.open_in_new),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: Text(AppInfo.privacyUrl),
            onTap: () => safeLaunchUrl(AppInfo.privacyUrl),
            trailing: const Icon(Icons.open_in_new),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            subtitle: Text(AppInfo.termsUrl),
            onTap: () => safeLaunchUrl(AppInfo.termsUrl),
            trailing: const Icon(Icons.open_in_new),
          ),

          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.article_outlined),
            title: const Text('Licenses'),
            subtitle: const Text('Open-source packages used'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppInfo.appName,
              applicationVersion: version,
              applicationIcon: const FlutterLogo(size: 36),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
