// lib/core/services/review_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_renting_group1/core/models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection de référence pour les avis.
  late final CollectionReference<Review> _reviewsRef;

  ReviewService() {
    _reviewsRef = _firestore.collection('reviews').withConverter<Review>(
          fromFirestore: (snapshot, _) => Review.fromFirestore(snapshot),
          toFirestore: (review, _) => review.toJson(),
        );
  }

  /// Poste un nouvel avis et met à jour la note moyenne de l'entité correspondante (logement ou étudiant).
  /// Utilise une transaction Firestore pour garantir l'atomicité des opérations.
  Future<void> postReview(Review review) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Crée une référence pour le nouveau document d'avis.
        final newReviewRef = _reviewsRef.doc();

        // 2. Détermine si l'avis concerne un logement ou un étudiant et prépare la référence.
        if (review.reviewerType == ReviewerType.student) {
          // Un étudiant note un logement.
          final propertyRef = _firestore.collection('listings').doc(review.propertyId);
          final propertySnapshot = await transaction.get(propertyRef);

          if (!propertySnapshot.exists) {
            throw Exception("Listing does not exist!");
          }

          // 3. Calcule la nouvelle note moyenne et le nombre d'avis.
          final currentReviewCount = propertySnapshot.data()?['reviewCount'] ?? 0;
          final currentAverageRating = (propertySnapshot.data()?['averageRating'] as num?)?.toDouble() ?? 0.0;
          
          final newReviewCount = currentReviewCount + 1;
          final newAverageRating = ((currentAverageRating * currentReviewCount) + review.rating) / newReviewCount;

          // 4. Effectue les écritures dans la transaction.
          transaction.set(newReviewRef, review);
          transaction.update(propertyRef, {
            'reviewCount': newReviewCount,
            'averageRating': newAverageRating,
          });

        } else {
          // Un propriétaire note un étudiant.
          final studentRef = _firestore.collection('users').doc(review.studentId);
          final studentSnapshot = await transaction.get(studentRef);

          if (!studentSnapshot.exists) {
            throw Exception("Student does not exist!");
          }

          // 3. Calcule la nouvelle note moyenne et le nombre de notes.
          final currentRatingCount = studentSnapshot.data()?['ratingCount'] ?? 0;
          final currentAverageRating = (studentSnapshot.data()?['averageRating'] as num?)?.toDouble() ?? 0.0;

          final newRatingCount = currentRatingCount + 1;
          final newAverageRating = ((currentAverageRating * currentRatingCount) + review.rating) / newRatingCount;

          // 4. Effectue les écritures dans la transaction.
          transaction.set(newReviewRef, review);
          transaction.update(studentRef, {
            'ratingCount': newRatingCount,
            'averageRating': newAverageRating,
          });
        }
      });
    } catch (e) {
      // Gérer l'erreur (par exemple, logger ou afficher un message à l'utilisateur)
      print("Failed to post review: $e");
      rethrow; // Propage l'erreur pour que l'UI puisse réagir.
    }
  }

  /// Récupère un flux (Stream) de tous les avis pour un logement spécifique.
  /// Le flux se met à jour automatiquement si de nouveaux avis sont ajoutés.
  Stream<List<Review>> getReviewsForProperty(String propertyId) {
    return _reviewsRef
        .where('propertyId', isEqualTo: propertyId)
        .where('reviewerType', isEqualTo: ReviewerType.student.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Récupère un flux (Stream) de toutes les notes pour un étudiant spécifique.
  Stream<List<Review>> getRatingsForStudent(String studentId) {
    return _reviewsRef
        .where('studentId', isEqualTo: studentId)
        .where('reviewerType', isEqualTo: ReviewerType.owner.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
