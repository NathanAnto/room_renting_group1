import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:room_renting_group1/core/models/booking.dart';
import 'package:room_renting_group1/core/models/user_model.dart';
import 'package:room_renting_group1/core/services/booking_service.dart';
import 'package:room_renting_group1/features/listings/screens/single_listing_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_renting_group1/features/listings/screens/create_listing_screen.dart';

import 'package:room_renting_group1/core/models/listing.dart';
import 'package:room_renting_group1/core/services/auth_service.dart';
import 'package:room_renting_group1/core/services/listing_service.dart';
import 'package:room_renting_group1/core/services/review_service.dart';
import 'package:room_renting_group1/features/listings/widgets/listing_card.dart';
import 'package:room_renting_group1/features/listings/screens/edit_listing_screen.dart';

import 'package:room_renting_group1/features/review/screens/rate_listing_screen.dart';
import 'package:room_renting_group1/features/review/screens/rate_student_screen.dart';

import '../../../core/services/profile_service.dart';

// --- Thème de couleurs inspiré des écrans de login ---
const Color primaryBlue = Color(0xFF0D47A1);
const Color lightGreyBackground = Color(0xFFF8F9FA);
const Color darkTextColor = Color(0xFF343A40);
const Color lightTextColor = Color(0xFF6C757D);

// Classe helper pour masquer la scrollbar
class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final ListingService _listingService = ListingService();
  final BookingService _bookingService = BookingService();
  final ProfileService _profileService = ProfileService();

  String? _userRole;
  UserModel? _currentUser;
  bool _isLoading = true;

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
      final userProfile = await _profileService.getUserProfile(user.uid);
      final listings =
          await _listingService.getListingsByOwner(user.uid).first;

      if (mounted) {
        setState(() {
          _currentUser = userProfile;
          _userRole = userProfile?.role.name;
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

  void _refreshData() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreyBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _buildBody(),
      floatingActionButton: const _CreateListingFab(),
    );
  }

  Widget _buildBody() {
    final user = _authService.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in.'));
    }

    Widget content;
    if (_userRole == 'homeowner') {
      content = _buildHomeownerView(user.uid);
    } else if (_userRole == 'student') {
      content = _buildStudentView(user.uid);
    } else {
      content = const Center(child: Text('Welcome to your dashboard.'));
    }

    return SafeArea(
      child: ScrollConfiguration(
        behavior: _NoScrollbarBehavior(),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: const Text(
                  'Your Dashboard',
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
              ),
            ];
          },
          body: content,
        ),
      ),
    );
  }

  Widget _buildHomeownerView(String ownerId) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildSection<Booking>(
          title: 'Pending Requests',
          stream: _bookingService.getPendingBookingsStreamForHomeowner(ownerId),
          itemBuilder: (booking) {
            final listingTitle =
                _listingsMap[booking.listingid]?.title ?? 'A Listing';
            return _PendingBookingCard(
              booking: booking,
              listingTitle: listingTitle,
              onAccept: () => _handleAcceptBooking(booking.id),
              onRefuse: () => _handleRefuseBooking(booking.id),
            );
          },
        ),
        _buildSection<Booking>(
          title: 'Students to Review',
          stream: _bookingService.getCompletedBookingsForHomeowner(ownerId),
          itemBuilder: (booking) {
            final listingTitle =
                _listingsMap[booking.listingid]?.title ?? 'A Listing';
            return _StudentToRateCard(
              booking: booking,
              listingTitle: listingTitle,
              onReviewSubmitted: _refreshData,
            );
          },
        ),
        _buildSection<Listing>(
          title: 'My Listings',
          stream: _listingService.getListingsByOwner(ownerId),
          itemBuilder: (listing) {
            return ListingCard(
              listing: listing,
              showEditButton: true,
              showDeleteButton: true,
              onEdit: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => EditListingScreen(listing: listing))),
              onDelete: () => _confirmDelete(listing),
              onViewDetails: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SingleListingScreen(listing: listing))),
            );
          },
          emptyMessage: 'You have not created any listings yet.',
        ),
      ],
    );
  }

  Widget _buildStudentView(String studentId) {
    return _buildSection<Booking>(
      title: 'My Bookings',
      stream: _bookingService.getBookingsByStudentId(studentId),
      itemBuilder: (booking) => _BookingCard(
        booking: booking,
        onReviewSubmitted: _refreshData,
      ),
      emptyMessage: 'You have no bookings yet.',
      showTitle: false,
    );
  }

  Widget _buildSection<T>({
    required String title,
    required Stream<List<T>> stream,
    required Widget Function(T item) itemBuilder,
    String emptyMessage = '',
    bool showTitle = true,
  }) {
    return StreamBuilder<List<T>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                  child: CircularProgressIndicator(color: primaryBlue)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return emptyMessage.isNotEmpty && showTitle
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                      child: Text(emptyMessage,
                          style: const TextStyle(
                              color: lightTextColor, fontSize: 16))))
              : const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkTextColor)),
              ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) => itemBuilder(items[index]),
              separatorBuilder: (context, index) => const SizedBox(height: 16),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // --- Handlers ---
  Future<void> _handleAcceptBooking(String? bookingId) async {
    if (bookingId == null) return;
    try {
      await _bookingService.acceptBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Booking accepted!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to accept booking: $e')));
      }
    }
  }

  Future<void> _handleRefuseBooking(String? bookingId) async {
    if (bookingId == null) return;
    try {
      await _bookingService.refuseBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Booking refused.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to refuse booking: $e')));
      }
    }
  }

  Future<void> _confirmDelete(Listing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
            'Are you sure you want to delete this listing? This action cannot be undone.'),
        actions: [
          TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false)),
          TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
    if (confirmed == true && listing.id != null) {
      try {
        await _listingService.deleteListing(listing.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Listing deleted successfully.')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting listing: $e')));
        }
      }
    }
  }
}

// --- Custom Cards ---

class _PendingBookingCard extends StatelessWidget {
  final Booking booking;
  final String listingTitle;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;
  static final ProfileService _profileService = ProfileService();

  const _PendingBookingCard(
      {required this.booking,
      required this.listingTitle,
      required this.onAccept,
      required this.onRefuse});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final dateRange =
        '${dateFormat.format(booking.start)} - ${dateFormat.format(booking.end)}';

    return ShadCard(
      backgroundColor: Colors.white,
      title: Text(listingTitle,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: darkTextColor)),
      description: Text(dateRange,
          style: const TextStyle(color: lightTextColor, fontSize: 15)),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ShadButton.outline(onPressed: onRefuse, child: const Text('Refuse')),
          const SizedBox(width: 8),
          ShadButton(
            backgroundColor: primaryBlue,
            onPressed: onAccept,
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      child: FutureBuilder<UserModel?>(
        future: _profileService.getUserProfile(booking.studentid),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Text('Loading student...',
                style: TextStyle(fontStyle: FontStyle.italic));
          final student = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('From: ${student.displayName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: darkTextColor)),
              if (student.phone != null && student.phone!.isNotEmpty)
                Text('Phone: ${student.phone}',
                    style: const TextStyle(color: lightTextColor)),
              if (student.email.isNotEmpty)
                Text('Email: ${student.email}',
                    style: const TextStyle(color: lightTextColor)),
            ],
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onReviewSubmitted;

  static final ProfileService _profileService = ProfileService();
  static final ListingService _listingService = ListingService();
  static final ReviewService _reviewService = ReviewService();

  const _BookingCard(
      {required this.booking, required this.onReviewSubmitted});

  Widget _buildStatusBadge(BookingStatus status) {
    if (status == BookingStatus.accepted) {
      return const ShadBadge(
          backgroundColor: Colors.green,
          child: Text('Accepted', style: TextStyle(color: Colors.white)));
    } else if (status == BookingStatus.pending) {
      return const ShadBadge.secondary(child: Text('Pending'));
    } else {
      return const ShadBadge.destructive(child: Text('Refused'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final dateRange =
        '${dateFormat.format(booking.start)} - ${dateFormat.format(booking.end)}';

    final bool isBookingFinished = booking.end.isBefore(DateTime.now());
    final bool canBeRated =
        isBookingFinished && booking.status == BookingStatus.accepted;

    return FutureBuilder<Listing?>(
      future: _listingService.getListing(booking.listingid),
      builder: (context, listingSnapshot) {
        if (listingSnapshot.connectionState == ConnectionState.waiting) {
          return const ShadCard(title: Text('Loading Listing...'));
        }

        final listingTitle =
            listingSnapshot.data?.title ?? 'Listing Not Found';
        final ownerId = listingSnapshot.data?.ownerId ?? '';

        return ShadCard(
          backgroundColor: Colors.white,
          title: Text(listingTitle,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: darkTextColor)),
          description: Text(dateRange,
              style: const TextStyle(color: lightTextColor, fontSize: 15)),
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FutureBuilder<UserModel?>(
                      future:
                          _profileService.getUserProfile(booking.homeownerid),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Text('Loading host...');
                        return Text('Host: ${snapshot.data?.displayName ?? 'N/A'}',
                            style: const TextStyle(color: lightTextColor));
                      },
                    ),
                  ),
                  _buildStatusBadge(booking.status),
                ],
              ),
              if (canBeRated)
                FutureBuilder<bool>(
                  future: _reviewService.hasStudentReviewedProperty(
                      booking.studentid, booking.listingid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting ||
                        snapshot.data == true) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ShadButton.outline(
                        width: double.infinity,
                        onPressed: () async {
                          final reviewWasSubmitted = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RateListingScreen(
                                  propertyId: booking.listingid,
                                  ownerId: ownerId),
                            ),
                          );
                          if (reviewWasSubmitted == true) onReviewSubmitted();
                        },
                        child: const Text('Rate Your Stay'),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentToRateCard extends StatelessWidget {
  final Booking booking;
  final String listingTitle;
  final VoidCallback onReviewSubmitted;

  static final ProfileService _profileService = ProfileService();
  static final ReviewService _reviewService = ReviewService();

  const _StudentToRateCard(
      {required this.booking,
      required this.listingTitle,
      required this.onReviewSubmitted});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _reviewService.hasOwnerReviewedStudent(
          booking.homeownerid, booking.studentid, booking.listingid),
      builder: (context, reviewSnapshot) {
        if (reviewSnapshot.connectionState == ConnectionState.waiting ||
            reviewSnapshot.data == true) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<UserModel?>(
          future: _profileService.getUserProfile(booking.studentid),
          builder: (context, studentSnapshot) {
            if (!studentSnapshot.hasData) return const SizedBox.shrink();
            final student = studentSnapshot.data!;
            
            // Utilisation de 'photoUrl' qui est le nom correct confirmé par user_model.dart
            final imageUrl = student.photoUrl;
            final hasAvatar = imageUrl != null && imageUrl.isNotEmpty;

            return ShadCard(
              backgroundColor: Colors.white,
              footer: SizedBox(
                width: double.infinity,
                child: ShadButton(
                  backgroundColor: primaryBlue,
                  onPressed: () async {
                    final reviewWasSubmitted = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RateStudentScreen(
                          studentId: booking.studentid,
                          propertyId: booking.listingid,
                          studentName: student.displayName,
                        ),
                      ),
                    );
                    if (reviewWasSubmitted == true) onReviewSubmitted();
                  },
                  child: const Text("Leave a Review",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: lightGreyBackground,
                    backgroundImage:
                        hasAvatar ? NetworkImage(imageUrl) : null,
                    child: !hasAvatar
                        ? const Icon(Icons.person_outline,
                            color: lightTextColor, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Review ${student.displayName}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: darkTextColor)),
                        const SizedBox(height: 2),
                        Text("For the stay at: $listingTitle",
                            style: const TextStyle(color: lightTextColor)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CreateListingFab extends StatefulWidget {
  const _CreateListingFab();

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
    if (!snap.exists) return false;

    final data = snap.data();
    final role = (data?['role'] ?? '').toString().toLowerCase();
    return role == 'homeowner';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _showFab,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          heroTag: 'create-listing-fab',
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateListingScreen())),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Listing',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: primaryBlue,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        );
      },
    );
  }
}