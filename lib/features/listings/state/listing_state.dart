// lib/state/listing_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/listing.dart';
import '../../../core/services/listing_service.dart';

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
final listingsProvider =
    StateNotifierProvider<ListingsNotifier, AsyncValue<List<Listing>>>(
  (ref) => ListingsNotifier(),
);

// 3. A provider to manage the loading state of a single listing.
final singleListingProvider =
    FutureProvider.family<Listing?, String>((ref, listingId) {
  final service = ListingService();
  return service.getListing(listingId);
});