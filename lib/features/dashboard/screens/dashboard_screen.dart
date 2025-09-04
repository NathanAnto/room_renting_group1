// lib/screens/dashboard_screen.dart (ou le chemin correspondant)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:room_renting_group1/core/models/booking.dart';
import 'package:room_renting_group1/core/models/user_model.dart';
import 'package:room_renting_group1/core/services/booking_service.dart';
import 'package:room_renting_group1/features/listings/screens/single_listing_screen.dart';
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

// --- Thème de couleurs cohérent ---
const Color primaryBlue = Color(0xFF0D47A1);
const Color lightGreyBackground = Color(0xFFF8F9FA);
const Color darkTextColor = Color(0xFF343A40);
const Color lightTextColor = Color(0xFF6C757D);
const Color goldColor = Color(0xFFFFC107);
const Color greenColor = Colors.green;
const Color redColor = Colors.red;


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
      if (!mounted) return;

      final listings =
          await _listingService.getListingsByOwner(user.uid).first;
      if (!mounted) return;

      setState(() {
        _currentUser = userProfile;
        _listingsMap = {
          for (var l in listings)
            if (l.id != null) l.id!: l,
        };
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching user data: $e");
      if (mounted) setState(() => _isLoading = false);
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
    if (user == null || _currentUser == null) {
      return const Center(child: Text('Please log in.'));
    }

    Widget content;
    if (_currentUser!.role == UserRole.homeowner) {
      content = _buildHomeownerView(user.uid);
    } else if (_currentUser!.role == UserRole.student) {
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
            return FutureBuilder<UserModel?>(
              future: _profileService.getUserProfile(booking.studentid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue)),
                    ),
                  );
                }
                final student = snapshot.data!;
                return _PendingBookingRequestCard(
                  booking: booking,
                  student: student,
                  onAccept: () => _handleAcceptBooking(booking.id),
                  onDecline: () => _handleRefuseBooking(booking.id),
                );
              },
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
    return ListView(
       padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildSection<Booking>(
          title: 'My Bookings',
          stream: _bookingService.getBookingsByStudentId(studentId),
          itemBuilder: (booking) => _BookingCard(
            booking: booking,
            onReviewSubmitted: _refreshData,
          ),
          emptyMessage: 'You have no bookings yet.',
        ),
      ],
    );
  }

  Widget _buildSection<T>({
    required String title,
    required Stream<List<T>> stream,
    required Widget Function(T item) itemBuilder,
    String emptyMessage = '',
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
          return emptyMessage.isNotEmpty
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
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 22,
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Booking accepted!'), backgroundColor: greenColor),
    );
  } catch (e, stackTrace) {
    // --- GESTION D'ERREUR FINALE ET ROBUSTE ---

    print("--- DÉBUT DE L'ERREUR DÉTAILLÉE ---");
    print('Type de l\'objet d\'erreur: ${e.runtimeType}');
    print('Erreur attrapée: $e');
    print('Stack Trace: $stackTrace');
    print("--- FIN DE L'ERREUR DÉTAILLÉE ---");

    String errorMessage = "An unknown error occurred.";

    if (e is FirebaseException) {
      // Cas 1: Erreur Firebase standard
      errorMessage = e.message ?? "Firebase error without a message.";
    } else {
      // Cas 2: C'est une NativeError ou autre. On analyse sa version texte.
      String potentialMessage = e.toString();
      
      // On cherche des mots-clés typiques d'erreur Firestore
      if (potentialMessage.contains("PERMISSION_DENIED")) {
        errorMessage = "Permission denied. Please check your Firestore security rules.";
      } else if (potentialMessage.contains("NOT_FOUND")) {
        errorMessage = "Document not found.";
      } else {
        // Si aucun mot-clé n'est trouvé, on affiche le message brut qui est souvent utile
        errorMessage = potentialMessage;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to accept booking: $errorMessage"), backgroundColor: redColor),
    );
  }
}


  Future<void> _handleRefuseBooking(String? bookingId) async {
    if (bookingId == null) return;
    try {
      await _bookingService.refuseBooking(bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking refused.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refuse booking: $e'), backgroundColor: redColor),
      );
    }
  }

  Future<void> _confirmDelete(Listing listing) async {
    final currentContext = context;
    final confirmed = await showDialog<bool>(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this listing? This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: redColor),
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed == true && listing.id != null) {
      try {
        await _listingService.deleteListing(listing.id!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing deleted successfully.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting listing: $e'), backgroundColor: redColor),
        );
      }
    }
  }
}

// --- CARTE DE DEMANDE DE RÉSERVATION (VERSION MATERIAL) ---
class _PendingBookingRequestCard extends StatelessWidget {
  final Booking booking;
  final UserModel student;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool isLoading;

  const _PendingBookingRequestCard({
    required this.booking,
    required this.student,
    required this.onAccept,
    required this.onDecline,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('d MMM', 'fr_FR');
    final String dateRange =
        '${formatter.format(booking.start)} - ${formatter.format(booking.end)}';

    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStudentHeader(),
            const Divider(height: 24),
            _buildBookingDetail(Icons.calendar_month_outlined, 'Dates', dateRange),
            const SizedBox(height: 12),
            _buildBookingDetail(Icons.nightlight_outlined, 'Nuits',
                '${booking.end.difference(booking.start).inDays}'),
            const Divider(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: primaryBlue.withOpacity(0.1),
          backgroundImage:
              (student.photoUrl != null && student.photoUrl!.isNotEmpty)
                  ? NetworkImage(student.photoUrl!)
                  : null,
          child: (student.photoUrl == null || student.photoUrl!.isEmpty) &&
                  student.displayName.isNotEmpty
              ? Text(
                  student.displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: primaryBlue),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.displayName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: darkTextColor),
              ),
              const SizedBox(height: 4),
              if (student.averageRating != null && student.averageRating! > 0)
                _buildStarRating(student.averageRating!, size: 18)
              else
                const Text('Aucune évaluation',
                    style: TextStyle(
                        color: lightTextColor, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: lightTextColor, size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: lightTextColor, fontSize: 13)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: darkTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ],
        )
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : onDecline,
            style: OutlinedButton.styleFrom(
              foregroundColor: redColor,
              side: BorderSide(color: redColor.withOpacity(0.5)),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Refuser'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: isLoading ? null : onAccept,
            style: FilledButton.styleFrom(
              backgroundColor: greenColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: isLoading
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Accepter'),
          ),
        ),
      ],
    );
  }
}

// --- AUTRES CARTES (Version Material) ---

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onReviewSubmitted;

  static final ProfileService _profileService = ProfileService();
  static final ListingService _listingService = ListingService();
  static final ReviewService _reviewService = ReviewService();

  const _BookingCard(
      {required this.booking, required this.onReviewSubmitted});

  Widget _buildStatusBadge(BookingStatus status) {
    Color badgeColor;
    String text;
    Color textColor = Colors.white;

    switch (status) {
      case BookingStatus.accepted:
        badgeColor = greenColor;
        text = 'Accepted';
        break;
      case BookingStatus.pending:
        badgeColor = Colors.orange;
        text = 'Pending';
        break;
      default:
        badgeColor = lightTextColor;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 12)),
    );
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
          return const Card(child: ListTile(title: Text('Loading Listing...')));
        }

        final listingTitle =
            listingSnapshot.data?.title ?? 'Listing Not Found';
        final ownerId = listingSnapshot.data?.ownerId ?? '';

        return Card(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(listingTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: darkTextColor)),
                  const SizedBox(height: 4),
                  Text(dateRange,
                      style: const TextStyle(color: lightTextColor, fontSize: 15)),
                  const Divider(height: 24),
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
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 40),
                              backgroundColor: primaryBlue
                            ),
                            onPressed: () async {
                              final currentContext = context;
                              final reviewWasSubmitted = await Navigator.push<bool>(
                                currentContext,
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
            
            final imageUrl = student.photoUrl;
            final hasAvatar = imageUrl != null && imageUrl.isNotEmpty;

            return Card(
                color: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                       Row(
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
                      const SizedBox(height: 16),
                       FilledButton(
                         style: FilledButton.styleFrom(
                           backgroundColor: primaryBlue,
                           minimumSize: const Size(double.infinity, 40)
                         ),
                        onPressed: () async {
                          final currentContext = context;
                          final reviewWasSubmitted = await Navigator.push<bool>(
                            currentContext,
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
                        child: const Text("Leave a Review"),
                      ),
                    ],
                  ),
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

/// Helper pour afficher les étoiles (pour l'affichage uniquement)
Widget _buildStarRating(double rating, {double size = 18, Color color = goldColor}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (index) {
      final double starValue = index + 1;
      IconData iconData = Icons.star_border_rounded;
      if (starValue <= rating) {
        iconData = Icons.star_rounded;
      } else if (starValue - 0.5 <= rating) {
        iconData = Icons.star_half_rounded;
      }
      return Icon(iconData, color: color, size: size);
    }),
  );
}