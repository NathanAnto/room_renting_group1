// lib/services/listing_service.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:room_renting_group1/core/models/listing.dart';

class ListingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collectionName = 'Listing';

  // Create a new listing
  Future<void> addListing(Listing listing) async {
    try {
      await _db.collection(collectionName).add(listing.toFirestore());
    } catch (e) {
      print('Error adding listing: $e');
    }
  }

  // Get a specific listing by its ID
  Future<Listing?> getListing(String listingId) async {
    try {
      DocumentSnapshot doc = await _db
          .collection(collectionName)
          .doc(listingId)
          .get();
      if (doc.exists) {
        return Listing.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting listing: $e');
      return null;
    }
  }

  Stream<List<Listing>> getFilteredListings({
    String? city,
    String? type,
    double? minRent,
    double? maxRent,
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
      print(type);
      query = query.where('type', isEqualTo: type);
    }
    // if (minRent != null) {
    //   query = query.where('rentPerMonth', isGreaterThanOrEqualTo: minRent);
    // }
    // if (maxRent != null) {
    //   query = query.where('rentPerMonth', isLessThanOrEqualTo: maxRent);
    // }
    // if (maxPublicTransportDistance != null) {
    //   query = query.where(
    //     'dist_public_transport_km',
    //     isLessThanOrEqualTo: maxPublicTransportDistance,
    //   );
    // }
    // if (maxProximHessoDistance != null) {
    //   query = query.where(
    //     'proxim_hesso_km',
    //     isLessThanOrEqualTo: maxProximHessoDistance,
    //   );
    // }
    // TODO: Add date range filtering

    return query.snapshots().map((snapshot) {
      List<Listing> listings =
          snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList();

      // 3. Apply ALL other filters here in the app (client-side).
      return listings.where((listing) {
        // Price Range Check
        if (minRent != null && listing.rentPerMonth < minRent) return false;
        if (maxRent != null && listing.rentPerMonth > maxRent) return false;

        // Distance Checks
        if (maxPublicTransportDistance != null &&
            listing.distanceToPublicTransportKm > maxPublicTransportDistance) {
          return false;
        }
        if (maxProximHessoDistance != null &&
            listing.proximHessoKm > maxProximHessoDistance) {
          return false;
        }
        // print(listing.amenities);
        // print('TYPE + ${type}');
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
  Stream<List<Listing>> getListings() {
    return _db
        .collection(collectionName)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList(),
        );
  }

  // Update an existing listing
  Future<void> updateListing(Listing listing) async {
    try {
      await _db
          .collection(collectionName)
          .doc(listing.id)
          .update(listing.toFirestore());
    } catch (e) {
      print('Error updating listing: $e');
    }
  }

  // Delete a listing by its ID
  Future<void> deleteListing(String listingId) async {
    try {
      await _db.collection(collectionName).doc(listingId).delete();
    } catch (e) {
      print('Error deleting listing: $e');
    }
  }

  // Function to search for addresses using Nominatim API
  Future<List<AddressResult>> searchAddresses(String query, bool city) async {
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
      return data.map((json) => AddressResult.fromJson(json)).toList();
    } else {
      print('Error searching addresses: ${response.statusCode}');
      return [];
    }
  }
}