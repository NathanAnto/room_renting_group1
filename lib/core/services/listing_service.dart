// lib/services/listing_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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
      DocumentSnapshot doc = await _db.collection(collectionName).doc(listingId).get();
      if (doc.exists) {
        return Listing.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting listing: $e');
      return null;
    }
  }

  Stream<List<Listing>> getFilteredListings(
      {String? city,
      String? type,
      double? minRent,
      double? maxRent,
      double? maxPublicTransportDistance,
      double? maxProximHessoDistance,
      List<String>? amenities,
      List<String>? listingIds}) {
    // Start with the base collection query
    Query<Map<String, dynamic>> query = _db.collection(collectionName);

    // Apply filters conditionally
    if (city != null && city.isNotEmpty) {
      query = query.where('city', isEqualTo: city);
    }
    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type);
    }
    if (minRent != null) {
      query = query.where('rentPerMonth', isGreaterThanOrEqualTo: minRent);
    }
    if (maxRent != null) {
      query = query.where('rentPerMonth', isLessThanOrEqualTo: maxRent);
    }
    if (maxPublicTransportDistance != null) {
      query = query.where('dist_public_transport_km', isLessThanOrEqualTo: maxPublicTransportDistance);
    }
    if (maxProximHessoDistance != null) {
      query = query.where('proxim_hesso_km', isLessThanOrEqualTo: maxProximHessoDistance);
    }
    if (amenities != null && amenities.isNotEmpty) {
       query = query.where('amenities', arrayContainsAny: amenities);
    }
    // TODO: Add date range filtering

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList());
  }

  // Get all listings as a stream
  Stream<List<Listing>> getListings() {
    return _db.collection(collectionName).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Listing.fromFirestore(doc)).toList());
  }

  // Update an existing listing
  Future<void> updateListing(Listing listing) async {
    try {
      await _db.collection(collectionName).doc(listing.id).update(listing.toFirestore());
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
}