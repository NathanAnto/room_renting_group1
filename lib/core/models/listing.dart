// lib/core/models/listing.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_renting_group1/core/models/ListingAvailability.dart';

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
  final ListingAvailability availability;
  final Map<String, bool> amenities;
  final String status; // tu gardes un String, comme souhaité
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
    final data = doc.data() as Map<String, dynamic>? ?? {};

    Map<String, dynamic> availMap = {};
    final rawAvail = data['availability'];
    if (rawAvail is Map<String, dynamic>) {
      availMap = rawAvail;
    } else if (rawAvail is Map) {
      availMap = Map<String, dynamic>.from(rawAvail);
    } else if (rawAvail is String) {
      // Sécurité migration: ancien champ String -> fenêtre vide
      availMap = {};
    }

    return Listing(
      id: doc.id,
      ownerId: (data['ownerId'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      type: (data['type'] ?? '') as String,
      rentPerMonth: _toDouble(data['rentPerMonth']),
      // tolère l’ancienne faute de frappe "perdictedRentPerMonth"
      predictedRentPerMonth: _toDouble(
        data['predictedRentPerMonth'] ?? data['perdictedRentPerMonth'],
      ),
      city: (data['city'] ?? '') as String,
      addressLine: (data['addressLine'] ?? '') as String,
      lat: _toDouble(data['lat']),
      lng: _toDouble(data['lng']),
      surface: _toDouble(data['surface']),
      distanceToPublicTransportKm: _toDouble(
        data['dist_public_transport_km'] ?? data['distanceToPublicTransportKm'],
      ),
      proximHessoKm: _toDouble(
        data['proxim_hesso_km'] ?? data['proximHessoKm'],
      ),
      numRooms: _toInt(data['num_rooms'] ?? data['numRooms']),
      availability: ListingAvailability.fromMap(availMap),
      amenities: Map<String, bool>.from(
        (data['amenities'] ?? <String, dynamic>{})
            .map((k, v) => MapEntry(k.toString(), v == true)),
      ),
      status: (data['status'] ?? 'draft') as String,
      createdAt: _toDate(data['createdAt']) ?? DateTime.now(),
      // tolère "updateAt" (ancien nom)
      updatedAt: _toDate(data['updatedAt'] ?? data['updateAt']) ?? DateTime.now(),
      images: List<String>.from(
        (data['images'] ?? const <dynamic>[]).map((e) => e.toString()),
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'type': type,
      'rentPerMonth': rentPerMonth,
      'predictedRentPerMonth': predictedRentPerMonth, // ✅ correct
      'city': city,
      'addressLine': addressLine,
      'lat': lat,
      'lng': lng,
      'surface': surface,
      'dist_public_transport_km': distanceToPublicTransportKm,
      'proxim_hesso_km': proximHessoKm,
      'num_rooms': numRooms,
      'availability': availability.toMap(), // ✅ nouveau mapping
      'amenities': amenities,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt, // ✅ correct
      'images': images,
    };
  }

  static const amenitiesLabels = {
    "is_furnished": "Furnished",
    "wifi_incl": "WiFi Included",
    "charges_incl": "Charges Included",
    "car_park": "Car Park",
  };

  // --- helpers de parsing ---
  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
