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
  final Map<String, bool> amenities;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> images; // Added images list

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
    required this.images, // Added images list to constructor
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
      predictedRentPerMonth: (data['perdictedRentPerMonth'] ?? 0.0).toDouble(),
      city: data['city'] ?? '',
      addressLine: data['addressLine'] ?? '',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      surface: (data['surface'] ?? 0.0).toDouble(),
      availability: data['availabilty'] ?? '',
      amenities: Map<String, bool>.from(data['amenities'] ?? {}),
      status: data['status'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updateAt'] as Timestamp).toDate(),
      images: List<String>.from(data['images'] ?? []), // Read images from Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'type': type,
      'rentPerMonth': rentPerMonth,
      'perdictedRentPerMonth': predictedRentPerMonth,
      'city': city,
      'addressLine': addressLine,
      'lat': lat,
      'lng': lng,
      'surface': surface,
      'availabilty': availability,
      'amenities': amenities,
      'status': status,
      'createdAt': createdAt,
      'updateAt': updatedAt,
      'images': images, // Write images to Firestore
    };
  }
}