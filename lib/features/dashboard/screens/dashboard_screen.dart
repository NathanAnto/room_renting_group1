import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:room_renting_group1/core/models/booking.dart';
import 'package:room_renting_group1/core/services/booking_service.dart';
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
  final BookingService _bookingService = BookingService();
  String? _userRole;
  bool _isLoading = true;

  // To store listings for easy title lookup
  Map<String, Listing> _listingsMap = {};

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      // Fetch role and listings in parallel to speed things up
      final roleFuture = FirebaseFirestore.instance
          .collection('Profile')
          .doc(user.uid)
          .get();
      // Use .first to treat the stream like a future for the initial load
      final listingsFuture = _listingService.getListingsByOwner(user.uid).first;

      final responses = await Future.wait([roleFuture, listingsFuture]);

      final roleSnap = responses[0] as DocumentSnapshot<Map<String, dynamic>>;
      final listings = responses[1] as List<Listing>;

      if (mounted) {
        setState(() {
          final data = roleSnap.data();
          if (data != null) {
            _userRole = (data['role'] ?? '').toString().toLowerCase();
          }
          // Create a map of listingId -> Listing object for quick lookups
          _listingsMap = {
            for (var l in listings)
              if (l.id != null) l.id!: l,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print("Error fetching user data: $e");
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
      return Column(
        children: [
          _buildPendingBookingsSection(user.uid),
          Expanded(child: _buildHomeownerListings(user.uid)),
        ],
      );
    } else if (_userRole == 'student') {
      return _buildStudentBookingsSection(user.uid); // const Center(child: Text('Your Booked Listings (coming soon!)'));
    }
    return const Center(child: Text('Welcome to your dashboard.'));
  }

  Widget _buildStudentBookingsSection(String studentId) {
    return StreamBuilder<List<Booking>>(
      stream: _bookingService.getBookingsByStudentId(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return const Center(
            child: Text('You have no bookings yet.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final listingTitle =
                _listingsMap[booking.listingid]?.title ?? 'A Listing';
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _BookingCard(
                booking: booking,
                listingTitle: listingTitle,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingBookingsSection(String ownerId) {
    return StreamBuilder<List<Booking>>(
      stream: _bookingService.getPendingBookingsStreamForHomeowner(ownerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _listingsMap.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Don't show anything if there are no pending bookings
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final bookings = snapshot.data!;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pending Requests',
                style: ShadTheme.of(context).textTheme.h4,
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  final listingTitle =
                      _listingsMap[booking.listingid]?.title ?? 'A Listing';
                  return _PendingBookingCard(
                    booking: booking,
                    listingTitle: listingTitle,
                    onAccept: () => _handleAcceptBooking(booking.id),
                    onRefuse: () => _handleRefuseBooking(booking.id),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
              ),
              const SizedBox(height: 16),
              const ShadSeparator.horizontal(
                thickness: 4,
                margin: EdgeInsets.symmetric(horizontal: 20),
                radius: BorderRadius.all(Radius.circular(4)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAcceptBooking(String? bookingId) async {
    if (bookingId == null) return;
    try {
      await _bookingService.acceptBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking accepted!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to accept booking: $e')));
      }
    }
  }

  Future<void> _handleRefuseBooking(String? bookingId) async {
    if (bookingId == null) return;
    try {
      await _bookingService.refuseBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking refused.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to refuse booking: $e')));
      }
    }
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

        // Update the listings map whenever new data arrives
        _listingsMap = {
          for (var l in listings)
            if (l.id != null) l.id!: l,
        };

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

class _PendingBookingCard extends StatelessWidget {
  final Booking booking;
  final String listingTitle;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;

  const _PendingBookingCard({
    required this.booking,
    required this.listingTitle,
    required this.onAccept,
    required this.onRefuse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final dateRange =
        '${dateFormat.format(booking.start)} - ${dateFormat.format(booking.end)}';

    return ShadCard(
      title: Text(listingTitle, style: theme.textTheme.large),
      description: Text(dateRange, style: theme.textTheme.muted),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ShadButton.outline(onPressed: onRefuse, child: const Text('Refuse')),
          const SizedBox(width: 8),
          ShadButton(onPressed: onAccept, child: const Text('Accept')),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final String listingTitle;

  const _BookingCard({
    required this.booking,
    required this.listingTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final dateRange = '${dateFormat.format(booking.start)} - ${dateFormat.format(booking.end)}';
    final status = booking.status.value;

    return ShadCard(
      title: Text(listingTitle, style: theme.textTheme.large),
      description: Text(dateRange, style: theme.textTheme.muted),
      child: ShadBadge.outline(
        child: Text(status, style: theme.textTheme.small),
      ),
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

    final snap = await FirebaseFirestore.instance
        .collection('Profile')
        .doc(user.uid)
        .get();
    final data = snap.data();
    if (data == null) return false;

    final role = (data['role'] ?? '').toString().toLowerCase();

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
