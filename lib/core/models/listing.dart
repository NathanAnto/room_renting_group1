// lib/core/models/listing.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Listing {
  final String? id;
  final String ownerId;
  final String title;
  final String description;
  final String type;
  final double rentPerMonth;
  final double predictedRentPerMonth;
  final String city;
  final String addressLine;
  final double lat;
  final double lng;
  final double surface;
  final String availability;
  final Map<String, dynamic> amenities;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> images;

  // --- AJOUTS POUR LES AVIS ---
  /// Note moyenne du logement, calculée à partir des avis des étudiants.
  final double averageRating;
  /// Nombre total d'avis reçus pour ce logement.
  final int reviewCount;
  // ---------------------------

  Listing({
    this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.type,
    required this.rentPerMonth,
    required this.predictedRentPerMonth,
    required this.city,
    required this.addressLine,
    required this.lat,
    required this.lng,
    required this.surface,
    required this.availability,
    required this.amenities,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
    // Initialisation des nouveaux champs.
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  factory Listing.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Listing(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      rentPerMonth: (data['rentPerMonth'] ?? 0.0).toDouble(),
      // Correction de la coquille 'perdictedRentPerMonth' -> 'predictedRentPerMonth'
      predictedRentPerMonth: (data['predictedRentPerMonth'] ?? 0.0).toDouble(),
      city: data['city'] ?? '',
      addressLine: data['addressLine'] ?? '',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      surface: (data['surface'] ?? 0.0).toDouble(),
      // Correction de la coquille 'availabilty' -> 'availability'
      availability: data['availability'] ?? '',
      amenities: data['amenities'] ?? {},
      status: data['status'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      // Correction de la coquille 'updateAt' -> 'updatedAt'
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      images: List<String>.from(data['images'] ?? []),
      // Lecture des nouveaux champs depuis Firestore.
      averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'type': type,
      'rentPerMonth': rentPerMonth,
      'predictedRentPerMonth': predictedRentPerMonth,
      'city': city,
      'addressLine': addressLine,
      'lat': lat,
      'lng': lng,
      'surface': surface,
      'availability': availability,
      'amenities': amenities,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'images': images,
      // Écriture des nouveaux champs dans Firestore.
      'averageRating': averageRating,
      'reviewCount': reviewCount,
    };
  }
}
