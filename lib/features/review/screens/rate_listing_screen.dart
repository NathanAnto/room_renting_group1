// lib/features/review/screens/rate_listing_screen.dart
import 'package:flutter/material.dart';
import 'package:room_renting_group1/core/models/listing.dart';
import 'package:room_renting_group1/core/models/review_model.dart';
import 'package:go_router/go_router.dart'; // Corrigé pour utiliser :
import 'package:room_renting_group1/core/services/auth_service.dart';
import 'package:room_renting_group1/core/services/listing_service.dart';
import 'package:room_renting_group1/core/services/review_service.dart';
import 'package:room_renting_group1/features/review/widgets/review_form.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RateListingScreen extends StatefulWidget {
  const RateListingScreen({
    super.key,
    required this.propertyId,
    required this.ownerId,
  });

  final String propertyId;
  final String ownerId;

  @override
  State<RateListingScreen> createState() => _RateListingScreenState();
}

class _RateListingScreenState extends State<RateListingScreen> {
  final ReviewService _reviewService = ReviewService();
  final AuthService _authService = AuthService();
  final ListingService _listingService = ListingService();
  late Future<Listing?> _listingFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // CORRECTION: On utilise le nom de méthode existant 'getListing'
    _listingFuture = _listingService.getListing(widget.propertyId);
  }

  Future<void> _handleSubmission({
    required double rating,
    required String comment,
  }) async {
    setState(() => _isSubmitting = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ShadToaster.of(context).show(
            const ShadToast.destructive(
              title: Text('Utilisateur non connecté'),
              description: Text('Vous devez être connecté pour laisser un avis.'),
            ),
          );
        }
        setState(() => _isSubmitting = false);
        return;
      }

      final newReview = Review(
        id: '',
        propertyId: widget.propertyId,
        studentId: currentUser.uid,
        ownerId: widget.ownerId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        reviewerType: ReviewerType.student,
      );

      await _reviewService.postReview(newReview);

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Avis envoyé !'),
            description: Text('Merci pour votre contribution.'),
          ),
        );
        context.pop();
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to post review: $e\n$stackTrace');
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Erreur'),
            description: Text("Impossible de poster l'avis. Veuillez réessayer."),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Évaluer votre séjour'),
      ),
      body: FutureBuilder<Listing?>(
        future: _listingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // CORRECTION: Suppression de 'const'
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Impossible de charger les informations du logement.',
                style: ShadTheme.of(context).textTheme.muted,
              ),
            );
          }
          final listing = snapshot.data!;
          return _buildContent(context, listing);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Listing listing) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ShadCard(
              title: Column(
                children: [
                  Text(
                    'Comment était votre séjour à',
                    style: ShadTheme.of(context).textTheme.muted,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    listing.title,
                    style: ShadTheme.of(context).textTheme.h3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: ShadTheme.of(context).radius,
                    child: CachedNetworkImage(
                      imageUrl: listing.images.first,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: ShadTheme.of(context).colorScheme.muted,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: ShadTheme.of(context).colorScheme.muted,
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ],
              ),
              description: Text(
                listing.addressLine,
                style: ShadTheme.of(context).textTheme.p,
                textAlign: TextAlign.center,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: ReviewForm(
                  isLoading: _isSubmitting,
                  onSubmit: _handleSubmission,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

