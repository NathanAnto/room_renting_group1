// lib/features/profile/screens/settings_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/services/app_info_service.dart';
import '../../../core/utils/launch_url.dart';
import 'about_screens.dart';

class SettingsScreen extends StatefulWidget {
  static const route = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '…';
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    AppInfoService.instance.packageInfo.then((pi) {
      if (mounted) setState(() => _version = '${pi.version}+${pi.buildNumber}');
    });
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Do you really want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // TODO: redirige vers l'écran de login si nécessaire
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Style “shadcn-like” : cartes arrondies, spacing généreux, icônes outlines
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AccountCard(user: _user, version: _version),

          const SizedBox(height: 16),
          _SectionHeader('General'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('Project name, version, team & links'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, AboutScreen.route),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  subtitle: const Text('Enable push notifications'),
                  value: true, // TODO: lier au state réel
                  onChanged: (v) {
                    // TODO: implémenter la sauvegarde du paramètre
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Privacy Policy'),
                  onTap: () => safeLaunchUrl(AppInfo.privacyUrl),
                  trailing: const Icon(Icons.open_in_new),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _SectionHeader('Support'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Report an issue'),
                  subtitle: const Text('Open a GitHub issue'),
                  onTap: () => safeLaunchUrl('${AppInfo.repoUrl}/issues'),
                  trailing: const Icon(Icons.open_in_new),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.star_rate_outlined),
                  title: const Text('Give feedback'),
                  onTap: () => safeLaunchUrl(AppInfo.repoUrl),
                  trailing: const Icon(Icons.open_in_new),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user, required this.version});
  final User? user;
  final String version;

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? 'Guest';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(email.isNotEmpty ? email[0].toUpperCase() : '?'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyMedium!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('App version $version', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.grey[700],
            letterSpacing: .4,
          ),
    );
  }
}
