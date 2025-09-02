// lib/core/services/review_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_renting_group1/core/models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Référence à la collection 'reviews' avec un convertisseur pour la sécurité des types.
  late final CollectionReference<Review> _reviewsRef;

  ReviewService() {
    _reviewsRef = _db.collection('Review').withConverter<Review>(
          fromFirestore: (snapshot, _) => Review.fromFirestore(snapshot),
          toFirestore: (review, _) => review.toJson(),
        );
  }

  /// Poste un nouvel avis et met à jour la note moyenne de manière atomique via une transaction.
  Future<void> postReview(Review review) async {
    // Détermine sur quelle collection et quel document la mise à jour doit avoir lieu.
    final isStudentReviewing = review.reviewerType == ReviewerType.student;
    final collectionPath = isStudentReviewing ? 'Listing' : 'Profile';
    final docId = isStudentReviewing ? review.propertyId : review.studentId;
    final docRef = _db.collection(collectionPath).doc(docId);

    return _db.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(docRef);

      if (!docSnapshot.exists) {
        throw Exception("Le document à noter n'existe pas !");
      }

      final data = docSnapshot.data() as Map<String, dynamic>;

      // CORRECTION : Gestion sécurisée des valeurs qui pourraient être nulles.
      // Si le champ n'existe pas, on utilise 0.0 ou 0 comme valeur par défaut.
      final oldRating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
      final oldRatingCount = data['reviewCount'] ?? 0;

      // Calcul de la nouvelle moyenne
      final newRatingCount = oldRatingCount + 1;
      final newAverageRating =
          ((oldRating * oldRatingCount) + review.rating) / newRatingCount;

      // 1. Écriture du nouveau document d'avis
      transaction.set(_reviewsRef.doc(), review);

      // 2. Mise à jour du document (logement ou étudiant) avec la nouvelle moyenne
      transaction.update(docRef, {
        'averageRating': newAverageRating,
        'reviewCount': newRatingCount,
      });
    });
  }

  /// Récupère en temps réel tous les avis pour un logement spécifique.
  Stream<List<Review>> getReviewsForProperty(String propertyId) {
    return _reviewsRef
        .where('propertyId', isEqualTo: propertyId)
        .where('reviewerType', isEqualTo: 'student')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Récupère en temps réel toutes les notes pour un étudiant spécifique.
  Stream<List<Review>> getRatingsForStudent(String studentId) {
    return _reviewsRef
        .where('studentId', isEqualTo: studentId)
        .where('reviewerType', isEqualTo: 'owner')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}
