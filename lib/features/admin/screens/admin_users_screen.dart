// lib/features/admin/screens/admin_users_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../admin/state/users_provider.dart';
import '../../../core/models/user_profile.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  static const route = '/admin/users';

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final asyncUsers = ref.watch(usersStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Users (read-only)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ShadCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header + filtre
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Registered Users',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: ShadInput(
                      placeholder: const Text('Rechercher nom ou rôle…'),
                      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                      leading: const Icon(Icons.search, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              // Contenu
              Expanded(
                child: asyncUsers.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(
                    child: ShadAlert.destructive(
                      title: const Text('Erreur'),
                      description: Text(e.toString()),
                    ),
                  ),
                  data: (users) {
                    final filtered = _filter(users, _query);
                    if (filtered.isEmpty) {
                      return const _EmptyState();
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final u = filtered[index];
                        final name = (u.displayName ?? '').trim().isEmpty
                            ? '—'
                            : u.displayName!.trim();
                        final role = (u.role ?? '').trim().isEmpty
                            ? 'user'
                            : u.role!.trim();

                        return ListTile(
                          title: Text(name),
                          trailing: ShadBadge(child: Text(role)),
                          // read-only: pas d'onTap
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<UserProfile> _filter(List<UserProfile> users, String q) {
    if (q.isEmpty) return users;
    return users.where((u) {
      final name = (u.displayName ?? '').toLowerCase();
      final role = (u.role ?? '').toLowerCase();
      return name.contains(q) || role.contains(q);
    }).toList();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search_outlined, size: 42),
            const SizedBox(height: 8),
            Text(
              'Aucun profil trouvé.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifie que la collection s’appelle bien "Profile" et que '
              'chaque document contient au moins "displayName" et "role".',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
