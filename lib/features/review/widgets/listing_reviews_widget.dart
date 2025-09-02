// lib/features/review/widgets/listing_reviews_widget.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour le formatage des dates
import 'package:room_renting_group1/core/models/review_model.dart';
import 'package:room_renting_group1/core/services/review_service.dart';

class ListingReviewsWidget extends StatefulWidget {
  final String propertyId;

  const ListingReviewsWidget({super.key, required this.propertyId});

  @override
  State<ListingReviewsWidget> createState() => _ListingReviewsWidgetState();
}

class _ListingReviewsWidgetState extends State<ListingReviewsWidget> {
  final ReviewService _reviewService = ReviewService();
  late final Stream<List<Review>> _reviewsStream;

  @override
  void initState() {
    super.initState();
    // On écoute le flux d'avis pour le logement concerné
    _reviewsStream = _reviewService.getReviewsForProperty(widget.propertyId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Review>>(
      stream: _reviewsStream,
      builder: (context, snapshot) {
        // Cas 1: En attente des données
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // Cas 2: Erreur lors de la récupération
        if (snapshot.hasError) {
          return Center(child: Text("Erreur de chargement des avis: ${snapshot.error}"));
        }
        // Cas 3: Aucune donnée ou liste vide
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                "Aucun avis pour le moment.",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          );
        }

        // Cas 4: On a les données, on les affiche
        final reviews = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${reviews.length} Avis",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true, // Pour que la liste prenne la hauteur de son contenu
              physics: const NeverScrollableScrollPhysics(), // La page parente gère le scroll
              itemCount: reviews.length,
              separatorBuilder: (context, index) => const Divider(height: 32),
              itemBuilder: (context, index) {
                return _ReviewCard(review: reviews[index]);
              },
            ),
          ],
        );
      },
    );
  }
}

/// Widget privé pour afficher une seule carte d'avis.
class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Affiche les étoiles
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
            const Spacer(),
            // Affiche la date formatée
            Text(
              DateFormat('d MMMM yyyy', 'fr_FR').format(review.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Affiche le commentaire
        Text(
          review.comment,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
