// lib/services/listing_service.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_renting_group1/core/models/listing.dart';
import 'package:room_renting_group1/core/models/ListingAvailability.dart';

class ListingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // IMPORTANT : colle à tes règles (match /Listing/{...})
  final String collectionName = 'Listing';

  // ----------------------------------------------------------------------------
  // Create
  // ----------------------------------------------------------------------------
  Future<void> addListing(Listing listing) async {
    try {
      // On recalcule l'index des mois pour rester cohérent avec le nouveau modèle
      final refreshedAvail = listing.availability.withRefreshedMonthsIndex();

      final data = listing.toFirestore();
      data['availability'] = refreshedAvail.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _db.collection(collectionName).add(data);
    } catch (e) {
      // ignore: avoid_print
      print('Error adding listing: $e');
      rethrow;
    }
  }

  // ----------------------------------------------------------------------------
  // Read one
  // ----------------------------------------------------------------------------
  Future<Listing?> getListing(String listingId) async {
    try {
      final doc = await _db.collection(collectionName).doc(listingId).get();
      if (!doc.exists) return null;
      return Listing.fromFirestore(doc);
    } catch (e) {
      // ignore: avoid_print
      print('Error getting listing: $e');
      return null;
    }
  }

  Stream<List<Listing>> getFilteredListings({
    String? city,
    String? type,
    double? minRent,
    double? maxRent,
    double? minSurface,
    double? maxSurface,
    double? maxPublicTransportDistance,
    double? maxProximHessoDistance,
    List<String>? amenities,
    List<String>? listingIds,
  }) {
    // Start with the base collection query
    Query<Map<String, dynamic>> query = _db.collection(collectionName);

    // Apply filters conditionally
    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }
    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type);
    }
    // TODO: Add date range filtering

    return query.snapshots().map((snapshot) {
      List<Listing> listings =
          snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList();

      // 3. Apply ALL other filters here in the app (client-side).
      return listings.where((listing) {
        // Price Range Check
        if (minRent != null && listing.rentPerMonth < minRent) return false;
        if (maxRent != null && listing.rentPerMonth > maxRent) return false;

        if (minSurface != null && listing.surface < minSurface) return false;
        if (maxSurface != null && listing.surface > maxSurface) return false;

        // Distance Checks
        if (maxPublicTransportDistance != null &&
            listing.distanceToPublicTransportKm > maxPublicTransportDistance) {
          return false;
        }
        if (maxProximHessoDistance != null &&
            listing.proximHessoKm > maxProximHessoDistance) {
          return false;
        }

        // Amenities Check
        if (amenities != null && amenities.isNotEmpty) {
          for (final amenity in amenities) {
            if (listing.amenities[amenity] != true) {
              return false; // Listing is missing a required amenity
            }
          }
        }

        // If all checks pass, keep the listing in the list
        return true;
      }).toList();
    });
  }

  // Get all listings as a stream
  // ----------------------------------------------------------------------------
  // Streams (sans index composite requis)
  // ----------------------------------------------------------------------------

  /// Stream de **tous** les listings (pas d'orderBy => pas d'index composite requis).
  Stream<List<Listing>> getListings() {
    return _db
        .collection(collectionName)
        .snapshots()
        .map((snap) => snap.docs.map(Listing.fromFirestore).toList());
  }

  /// Public uniquement : filtre simple sur `status == "active"` (pas d'orderBy).
  /// -> ne nécessite pas d'index composite.
  Stream<List<Listing>> getPublicListings() {
    return _db
        .collection(collectionName)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) => snap.docs.map(Listing.fromFirestore).toList());
  }

  /// Public + tri côté client (pour éviter l'index sur orderBy).
  Stream<List<Listing>> getPublicListingsSortedNewestFirst() {
    return getPublicListings().map((list) {
      list.sort((a, b) => (b.createdAt).compareTo(a.createdAt));
      return list;
    });
  }

  /// Par propriétaire (pas d'orderBy => pas d'index composite requis).
  Stream<List<Listing>> getListingsByOwner(String ownerId) {
    return _db
        .collection(collectionName)
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) => snap.docs.map(Listing.fromFirestore).toList());
  }

  // ----------------------------------------------------------------------------
  // Update
  // ----------------------------------------------------------------------------
  Future<void> updateListing(Listing listing) async {
    try {
      if (listing.id == null || listing.id!.isEmpty) {
        throw ArgumentError('updateListing: missing listing.id');
      }
      final refreshedAvail = listing.availability.withRefreshedMonthsIndex();

      final data = listing.toFirestore();
      data['availability'] = refreshedAvail.toMap();
      // On laisse createdAt tel quel côté Firestore
      data.remove('createdAt');
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _db.collection(collectionName).doc(listing.id!).update(data);
    } catch (e) {
      // ignore: avoid_print
      print('Error updating listing: $e');
      rethrow;
    }
  }

  // ----------------------------------------------------------------------------
  // Delete
  // ----------------------------------------------------------------------------
  Future<void> deleteListing(String listingId) async {
    try {
      await _db.collection(collectionName).doc(listingId).delete();
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting listing: $e');
      rethrow;
    }
  }

  // Function to search for addresses using Nominatim API
  Future<List<OsmPlace>> searchAddresses(String query, bool city) async {
    if (query.isEmpty) {
      return [];
    }

    // Build the Nominatim API URL with search parameters
    var url = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'json',
      'addressdetails': '1',
      'limit': '10',
      'countrycodes': 'ch',
    });

    // search for city only if city is true
    if (city) {
      url = url.replace(queryParameters: {
        ...url.queryParameters,
        'city': query,
      });
    } else {
      url = url.replace(queryParameters: {
        ...url.queryParameters,
        'q': query,
      });      
    }

    // Add User-Agent header as required by Nominatim usage policy
    final response = await http.get(
      url,
      headers: {'User-Agent': 'PropertyFinderApp/1.0'},
    );

    if (response.statusCode == 200) {
      // Parse the JSON response
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => OsmPlace.fromJson(json)).toList();
    } else {
      print('Error searching addresses: ${response.statusCode}');
      return [];
    }
  }
}
