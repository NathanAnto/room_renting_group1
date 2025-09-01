import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../widgets/listing_card.dart';
import '../widgets/listing_filter_bottom_sheet.dart';
import '../state/listing_state.dart';
import 'single_listing_screen.dart';
import '../../../core/models/filter_options.dart';

class ListingsScreen extends ConsumerWidget {
  const ListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsyncValue = ref.watch(listingsProvider);
    final theme = ShadTheme.of(context);
    final filterOptions = ref.watch(filterOptionsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Available Listings', style: TextStyle(fontSize: 20)),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ShadInput(
                    placeholder: const Row(
                      children: [
                        Icon(Icons.search, size: 18),
                        SizedBox(width: 8),
                        Text('Search for a City...'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                ShadButton.secondary(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext ctx) {
                        return const FilterBottomSheet();
                      },
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.slidersHorizontal, size: 16),
                      SizedBox(width: 8),
                      Text('Filters'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: listingsAsyncValue.when(
              data: (listings) {
                if (listings.isEmpty) {
                  return const Center(
                    child: Text('No listings available at the moment.'),
                  );
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
                              builder: (context) =>
                                  SingleListingScreen(listing: listing),
                            ),
                          );
                        },
                        onContactHost: () {
                          print('Contact host for ${listing.title}');
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Error loading listings: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

