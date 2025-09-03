import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_renting_group1/features/listings/screens/create_listing_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontSize: 20)),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: const Center(
        child: Text(''),
      ),
      floatingActionButton: const _CreateListingFab(),
    );
  }
}

class _CreateListingFab extends StatefulWidget {
  const _CreateListingFab({Key? key}) : super(key: key);

  @override
  State<_CreateListingFab> createState() => _CreateListingFabState();
}

class _CreateListingFabState extends State<_CreateListingFab> {
  late final Future<bool> _showFab;

  @override
  void initState() {
    super.initState();
    _showFab = _isHomeowner();
  }

  Future<bool> _isHomeowner() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Lecture du profil dans la collection "Profile" (conforme à tes règles/Services)
    final snap =
        await FirebaseFirestore.instance.collection('Profile').doc(user.uid).get();
    final data = snap.data();
    if (data == null) return false;

    // Le champ correct est "role" (ex: "student" | "homeowner" | "admin")
    final role = (data['role'] ?? '').toString().toLowerCase();

    // Montre le FAB uniquement aux propriétaires
    return role == 'homeowner';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _showFab,
      builder: (context, snapshot) {
        final show = snapshot.data == true;
        if (!show) return const SizedBox.shrink();

        return FloatingActionButton.extended(
          heroTag: 'create-listing-fab',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CreateListingScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add_home_work_outlined),
          label: const Text('New Listing'),
        );
      },
    );
  }
}
