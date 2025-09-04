import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/review_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/review_service.dart';

// --- Thème de couleurs cohérent ---
const Color primaryBlue = Color(0xFF0D47A1);
const Color darkTextColor = Color(0xFF343A40);
const Color lightTextColor = Color(0xFF6C757D);
const Color dividerColor = Color(0xFFE9ECEF);
const Color goldColor = Color(0xFFFFC107);

class ListingReviewsWidget extends StatefulWidget {
  final String propertyId;

  const ListingReviewsWidget({super.key, required this.propertyId});

  @override
  State<ListingReviewsWidget> createState() => _ListingReviewsWidgetState();
}

class _ListingReviewsWidgetState extends State<ListingReviewsWidget> {
  final ReviewService _reviewService = ReviewService();
  final ProfileService _profileService = ProfileService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Review>>(
      stream: _reviewService.getReviewsForProperty(widget.propertyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: primaryBlue));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildSection(
            title: 'Évaluations des étudiants',
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'Aucun avis pour le moment. Soyez le premier !',
                  style: TextStyle(color: lightTextColor, fontSize: 16),
                ),
              ),
            ),
          );
        }

        final reviews = snapshot.data!;
        final averageRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

        return _buildSection(
          title: 'Évaluations des étudiants',
          child: Column(
            children: [
              _buildAverageRatingHeader(averageRating, reviews.length),
              const Divider(height: 1, color: dividerColor),
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: reviews.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return FutureBuilder<UserModel?>(
                    future: _profileService.getUserProfile(review.studentId),
                    builder: (context, userSnapshot) {
                      // Gère les états de chargement et d'erreur de manière non bloquante
                      final user = userSnapshot.data;
                      return _ReviewCard(review: review, user: user);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Header affichant la note moyenne du logement.
  Widget _buildAverageRatingHeader(double rating, int reviewCount) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(Icons.star_rounded, color: goldColor, size: 28),
          const SizedBox(width: 12),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: darkTextColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'sur 5 · basé sur $reviewCount avis',
            style: const TextStyle(color: lightTextColor, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// Widget pour afficher une seule carte d'avis.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, this.user});

  final Review review;
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    final displayName = user?.displayName ?? 'Étudiant anonyme';
    final photoUrl = user?.photoUrl;
    final studentAverageRating = user?.averageRating ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: primaryBlue.withOpacity(0.1),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty) && displayName.isNotEmpty
                    ? Text(
                        displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: darkTextColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // NOUVEAU: Note moyenne de l'étudiant
                        _buildStarRating(studentAverageRating, size: 15, color: lightTextColor.withOpacity(0.7)),
                      ],
                    ),
                    Text(
                      DateFormat('d MMMM yyyy', 'fr_FR').format(review.createdAt),
                      style: const TextStyle(color: lightTextColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStarRating(review.rating, size: 18), // Note pour le logement
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: const TextStyle(color: darkTextColor, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// --- Widgets et Fonctions Helper Réutilisables ---

/// Construit une section générique avec un titre et un contenu dans une carte.
Widget _buildSection({required String title, required Widget child}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: darkTextColor,
          ),
        ),
      ),
      ShadCard(
        backgroundColor: Colors.white,
        padding: EdgeInsets.zero,
        child: child,
      ),
    ],
  );
}

/// Construit la rangée d'étoiles pour une note donnée.
Widget _buildStarRating(double rating, {double size = 18, Color color = goldColor}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (index) {
      // Calcule si l'étoile doit être pleine, à moitié ou vide
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