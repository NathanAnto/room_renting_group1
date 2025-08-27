// lib/models/listing.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Listing {
  final String? id;
  final String ownerId;
  final String title;
  final String description;
  final String type;
  final double rentPerMonth;
  final double predictedRentPerMonth; // Corrected field name
  final String city;
  final String addressLine; // Corrected field name
  final double lat;
  final double lng;
  final double surface;
  final String availability; // Changed to String
  final Map<String, bool> amenities;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

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
      predictedRentPerMonth: (data['perdictedRentPerMonth'] ?? 0.0).toDouble(), // Use the field name as it is in your database
      city: data['city'] ?? '',
      addressLine: data['addressLine'] ?? '', // Use the correct field name
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      surface: (data['surface'] ?? 0.0).toDouble(),
      availability: data['availabilty'] ?? '', // Use the correct field name and type
      amenities: Map<String, bool>.from(data['amenities'] ?? {}),
      status: data['status'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updateAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'type': type,
      'rentPerMonth': rentPerMonth,
      'perdictedRentPerMonth': predictedRentPerMonth, // Match the database field name
      'city': city,
      'addressLine': addressLine, // Match the database field name
      'lat': lat,
      'lng': lng,
      'surface': surface,
      'availabilty': availability, // Match the database field name
      'amenities': amenities,
      'status': status,
      'createdAt': createdAt,
      'updateAt': updatedAt, // Match the database field name
    };
  }
}