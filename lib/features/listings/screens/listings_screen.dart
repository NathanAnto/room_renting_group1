// lib/features/listings/screens/listings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../widgets/listing_card.dart';
import '../state/listing_state.dart';
import 'single_listing_screen.dart';

class ListingsScreen extends ConsumerWidget {
  const ListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsyncValue = ref.watch(listingsProvider);
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Available Listings'),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: listingsAsyncValue.when(
        data: (listings) {
          if (listings.isEmpty) {
            return const Center(child: Text('No listings available at the moment.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ListingCard(
                  listing: listing,
                  onViewDetails: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SingleListingScreen(listing: listing),
                      ),
                    );
                  },
                  onContactHost: () {
                    // TODO: Implement contact host functionality
                    print('Contact host for ${listing.title}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading listings: $error')),
      ),
    );
  }
}