// lib/state/listing_state.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_renting_group1/features/listings/state/filter_state.dart';
import '../../../core/models/listing.dart';
import '../../../core/services/listing_service.dart';
import '../screens/listings_screen.dart';

// 1. A StateNotifier to manage the list of listings.
//    This allows for adding, updating, and deleting listings in the app's state.
class ListingsNotifier extends StateNotifier<AsyncValue<List<Listing>>> {
  ListingsNotifier() : super(const AsyncValue.loading()) {
    _fetchListings();
  }

  final ListingService _listingService = ListingService();

  Future<void> _fetchListings() async {
    try {
      // Use the stream from the service to listen for real-time updates from Firebase
      _listingService.getListings().listen(
        (listings) {
          state = AsyncValue.data(listings);
        },
        onError: (error) {
          state = AsyncValue.error(error, StackTrace.current);
        },
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Method to add a new listing
  Future<void> addListing(Listing listing) async {
    // Optimistically update the UI while the async operation is in progress.
    state = state.whenData((listings) {
      // Add a temporary listing to the local state
      return [...listings, listing];
    });

    try {
      await _listingService.addListing(listing);
    } catch (e, st) {
      // If the operation fails, revert the state
      state = AsyncValue.error(e, st);
    }
  }

  // Method to update an existing listing
  Future<void> updateListing(Listing updatedListing) async {
    // Optimistically update the UI
    state = state.whenData((listings) {
      return [
        for (final listing in listings)
          if (listing.id == updatedListing.id) updatedListing else listing,
      ];
    });
    try {
      await _listingService.updateListing(updatedListing);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Method to delete a listing
  Future<void> deleteListing(String listingId) async {
    // Optimistically update the UI
    state = state.whenData((listings) {
      return listings.where((l) => l.id != listingId).toList();
    });
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
    minRent: filters.priceRange?.start,
    maxRent: filters.priceRange?.end,
    city: filters.city,
    type: filters.type,
    maxProximHessoDistance: filters.maxHessoDist,
    maxPublicTransportDistance: filters.maxTransportDist,
    amenities: selectedAmenities,
    // Add other filters like surface and numRooms if needed in getFilteredListings
  );
});