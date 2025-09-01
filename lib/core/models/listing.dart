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
  final double distanceToPublicTransportKm;
  final double proximHessoKm;
  final int numRooms;
  final String availability;
  final Map<String, bool> amenities;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> images;

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
    required this.distanceToPublicTransportKm,
    required this.proximHessoKm,
    required this.numRooms,
    required this.availability,
    required this.amenities,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
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
      predictedRentPerMonth: (data['predictedRentPerMonth'] ?? 0.0).toDouble(),
      city: data['city'] ?? '',
      addressLine: data['addressLine'] ?? '',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      surface: (data['surface'] ?? 0.0).toDouble(),
      distanceToPublicTransportKm: (data['dist_public_transport_km'] ?? 0.0)
          .toDouble(),
      proximHessoKm: (data['proxim_hesso_km'] ?? 0.0).toDouble(),
      numRooms: (data['num_rooms'] ?? 0).toInt(),
      availability: data['availability'] ?? '',
      amenities:
          (data['amenities'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              value is bool ? value : value == 1, // conversion int->bool
            ),
          ) ??
          {},
      status: data['status'] ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      images: List<String>.from(data['images'] ?? []),
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
      'dist_public_transport_km': distanceToPublicTransportKm,
      'proxim_hesso_km': proximHessoKm,
      'num_rooms': numRooms,
      'availabilty': availability,
      'amenities': amenities,
      'status': status,
      'createdAt': createdAt,
      'updateAt': updatedAt,
      'images': images, // Write images to Firestore
    };
  }

  static const amenitiesLabels = {
    "is_furnished": "Furnished",
    "wifi_incl": "WiFi Included",
    "charges_incl": "Charges Included",
    "car_park": "Car Park",
  };
}
