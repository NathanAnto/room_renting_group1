// lib/core/models/review_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum pour définir qui laisse l'avis.
/// Cela rend le code plus lisible et moins sujet aux erreurs que d'utiliser des chaînes de caractères.
enum ReviewerType {
  student,
  owner,
}

class Review {
  /// L'ID unique du document d'avis dans Firestore.
  final String id;

  /// L'ID de la propriété (logement) qui est évaluée ou pour laquelle la location a eu lieu.
  final String propertyId;

  /// L'ID de l'étudiant impliqué dans l'avis (soit celui qui écrit, soit celui qui est noté).
  final String studentId;

  /// L'ID du propriétaire impliqué dans l'avis.
  final String ownerId;

  /// La note donnée, généralement sur une échelle de 1 à 5.
  final double rating;

  /// Le commentaire textuel laissé par l'évaluateur.
  final String comment;

  /// La date et l'heure de création de l'avis.
  final DateTime createdAt;

  /// Le type d'évaluateur (étudiant ou propriétaire).
  final ReviewerType reviewerType;

  Review({
    required this.id,
    required this.propertyId,
    required this.studentId,
    required this.ownerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.reviewerType,
  });

  /// Méthode pour convertir un objet Review en Map<String, dynamic>.
  /// C'est le format requis pour écrire des données dans Firestore.
  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'studentId': studentId,
      'ownerId': ownerId,
      'rating': rating,
      'comment': comment,
      // On convertit DateTime en Timestamp Firestore pour un stockage correct.
      'createdAt': Timestamp.fromDate(createdAt),
      // On stocke l'enum sous forme de chaîne de caractères.
      'reviewerType': reviewerType.name,
    };
  }

  /// Factory constructor pour créer une instance de Review à partir d'un document Firestore.
  /// Prend un DocumentSnapshot qui contient les données et l'ID du document.
  factory Review.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    // Récupère les données du document. S'il n'y a pas de données, on utilise une map vide.
    final data = doc.data() ?? {};

    return Review(
      // L'ID vient directement du DocumentSnapshot, pas des données.
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      studentId: data['studentId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      // S'assure que la note est bien un double.
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] ?? '',
      // Convertit le Timestamp Firestore en objet DateTime.
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Convertit la chaîne de caractères stockée en enum ReviewerType.
      // Si la valeur est invalide ou absente, on utilise 'student' par défaut.
      reviewerType: ReviewerType.values.firstWhere(
        (e) => e.name == data['reviewerType'],
        orElse: () => ReviewerType.student,
      ),
    );
  }
}
