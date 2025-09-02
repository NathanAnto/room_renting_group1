// lib/state/listing_state.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_renting_group1/features/listings/state/filter_state.dart';
import '../../../core/models/listing.dart';
import '../../../core/services/listing_service.dart';
import '../screens/listings_screen.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:room_renting_group1/core/models/listing.dart';
import 'package:room_renting_group1/core/services/listing_service.dart';

class ListingsNotifier extends StateNotifier<AsyncValue<List<Listing>>> {
  ListingsNotifier() : super(const AsyncValue.loading()) {
    _subscribe();
  }

  final ListingService _listingService = ListingService();
  StreamSubscription<List<Listing>>? _sub;

  void _subscribe() {
    // Stream simple (pas d'index composite requis)
    _sub = _listingService.getListings().listen(
      (listings) => state = AsyncValue.data(listings),
      onError: (error, stack) => state = AsyncValue.error(error, stack),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> addListing(Listing listing) async {
    // Optimistic UI (le stream écrasera ensuite avec la vérité serveur)
    state = state.whenData((list) => [...list, listing]);
    try {
      await _listingService.addListing(listing);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateListing(Listing updatedListing) async {
    final id = updatedListing.id;
    if (id == null || id.isEmpty) {
      state = AsyncValue.error(
        ArgumentError('updateListing: missing listing.id'),
        StackTrace.current,
      );
      return;
    }

    // Optimistic UI
    state = state.whenData((list) => [
          for (final l in list) (l.id == id) ? updatedListing : l,
        ]);

    try {
      await _listingService.updateListing(updatedListing);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteListing(String listingId) async {
    // Optimistic UI
    state = state.whenData(
      (list) => list.where((l) => l.id != listingId).toList(),
    );
    try {
      await _listingService.deleteListing(listingId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// 2. The provider that exposes the ListingsNotifier.
//    This is the entry point for widgets to access the listings state.
final listingsProvider = StreamProvider<List<Listing>>((ref) {
  // Watch the filter options
  final filters = ref.watch(filterOptionsProvider);
  final listingService = ListingService(); // Assuming you have a service instance

  // Get amenities that are true
  final selectedAmenities = filters.amenities?.entries
    .where((entry) => entry.value == true)
    .map((entry) => entry.key)
    .toList();
    
  return listingService.getFilteredListings(
    city: filters.city,
    type: filters.type,
    minRent: filters.priceRange?.start,
    maxRent: filters.priceRange?.end,
    minSurface: filters.surfaceRange?.start,
    maxSurface: filters.surfaceRange?.end,
    maxProximHessoDistance: filters.maxHessoDist,
    maxPublicTransportDistance: filters.maxTransportDist,
    amenities: selectedAmenities,
    // Add other filters like surface and numRooms if needed in getFilteredListings
  );
});

// Charger un listing unique
final singleListingProvider =
    FutureProvider.family<Listing?, String>((ref, listingId) {
  final service = ListingService();
  return service.getListing(listingId);
});

// Mes listings (filtré côté client sur le stream global)
final myListingsProvider = StreamProvider.autoDispose<List<Listing>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ListingService()
      .getListings()
      .map((all) => all.where((l) => l.ownerId == uid).toList());
});
