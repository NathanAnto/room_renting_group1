import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:intl/intl.dart'; // Pour le formatage des dates

import '../../../core/models/review_model.dart';
import '../../../core/models/user_model.dart'; // Importer le UserModel
import '../../../core/services/profile_service.dart'; // MISE À JOUR: Utilisation du vrai service
import '../../../core/services/review_service.dart';

class ListingReviewsWidget extends StatefulWidget {
  final String propertyId;

  const ListingReviewsWidget({super.key, required this.propertyId});

  @override
  State<ListingReviewsWidget> createState() => _ListingReviewsWidgetState();
}

class _ListingReviewsWidgetState extends State<ListingReviewsWidget> {
  final ReviewService _reviewService = ReviewService();
  // MISE À JOUR: Instance du ProfileService correct
  final ProfileService _profileService = ProfileService();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return StreamBuilder<List<Review>>(
      stream: _reviewService.getReviewsForProperty(widget.propertyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}',
              style: TextStyle(color: theme.colorScheme.destructive));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'Aucun avis d\'étudiant pour le moment. Soyez le premier !',
                style: theme.textTheme.muted,
              ),
            ),
          );
        }

        final reviews = snapshot.data!;
        final averageRating =
            reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section pour la note moyenne
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: theme.textTheme.h4.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStarRating(averageRating, size: 20),
                    Text(
                      'Basé sur ${reviews.length} avis',
                      style: theme.textTheme.muted,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Liste des avis
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: reviews.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 24),
              itemBuilder: (context, index) {
                final review = reviews[index];
                
                // MISE À JOUR: Utilisation de FutureBuilder avec ProfileService
                return FutureBuilder<UserModel?>(
                  future: _profileService.getUserProfile(review.studentId),
                  builder: (context, userSnapshot) {
                    // On affiche un nom par défaut pendant le chargement ou en cas d'erreur
                    final userName = userSnapshot.data?.displayName ?? 'Étudiant anonyme';

                    return _ReviewCard(
                      review: review,
                      userName: userName,
                      theme: theme,
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Widget pour l'affichage des étoiles
  Widget _buildStarRating(double rating, {double size = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }
}

/// Widget privé pour afficher une seule carte d'avis.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.userName,
    required this.theme,
  });

  final Review review;
  final String userName;
  final ShadThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // MISE À JOUR: Affichage du nom récupéré
            Expanded(
              child: Text(
                userName,
                style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('d MMMM yyyy', 'fr_FR').format(review.createdAt),
              style: theme.textTheme.muted,
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildStarRating(review.rating, size: 16),
        const SizedBox(height: 8),
        Text(
          review.comment,
          style: theme.textTheme.p.copyWith(color: theme.colorScheme.foreground),
        ),
      ],
    );
  }

  // Duplication de la méthode pour qu'elle soit accessible ici
  Widget _buildStarRating(double rating, {double size = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }
}