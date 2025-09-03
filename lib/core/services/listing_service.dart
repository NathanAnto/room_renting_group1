// lib/services/listing_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_renting_group1/core/models/listing.dart';

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
}
