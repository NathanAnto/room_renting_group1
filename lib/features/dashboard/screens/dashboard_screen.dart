import 'package:flutter/material.dart';
import 'package:room_renting_group1/features/listings/screens/single_listing_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_renting_group1/features/listings/screens/create_listing_screen.dart';
import 'package:room_renting_group1/core/models/listing.dart';
import 'package:room_renting_group1/core/services/auth_service.dart';
import 'package:room_renting_group1/core/services/listing_service.dart';
import 'package:room_renting_group1/features/listings/widgets/listing_card.dart';
import 'package:room_renting_group1/features/listings/screens/edit_listing_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final ListingService _listingService = ListingService();
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('Profile')
          .doc(user.uid)
          .get();
      final data = snap.data();
      if (data != null && mounted) {
        setState(() {
          _userRole = (data['role'] ?? '').toString().toLowerCase();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error appropriately
      print("Error fetching user role: $e");
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: const _CreateListingFab(),
    );
  }

  Widget _buildBody() {
    final user = _authService.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in.'));
    }

    if (_userRole == 'homeowner') {
      return _buildHomeownerListings(user.uid);
    } else if (_userRole == 'student') {
      // Placeholder for student's booked listings
      return const Center(child: Text('Your Booked Listings (coming soon!)'));
    }
    return const Center(child: Text('Welcome to your dashboard.'));
  }

  Widget _buildHomeownerListings(String ownerId) {
    return StreamBuilder<List<Listing>>(
      stream: _listingService.getListingsByOwner(ownerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return const Center(
            child: Text('You have not created any listings yet.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ListingCard(
                listing: listing,
                showEditButton: true,
                showDeleteButton: true,
                onEdit: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditListingScreen(listing: listing),
                    ),
                  );
                },
                onDelete: () => _confirmDelete(listing),
                onViewDetails: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SingleListingScreen(listing: listing),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(Listing listing) async {
    final confirmed = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog(
        title: const Text('Confirm Deletion'),
        description: const Text(
          'Are you sure you want to delete this listing? This action cannot be undone.',
        ),
        actions: [
          ShadButton.ghost(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ShadButton.destructive(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && listing.id != null) {
      try {
        await _listingService.deleteListing(listing.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing deleted successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting listing: $e')));
        }
      }
    }
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
    final snap = await FirebaseFirestore.instance
        .collection('Profile')
        .doc(user.uid)
        .get();
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
              MaterialPageRoute(builder: (_) => const CreateListingScreen()),
            );
          },
          icon: const Icon(Icons.add_home_work_outlined),
          label: const Text('New Listing'),
        );
      },
    );
  }
}
