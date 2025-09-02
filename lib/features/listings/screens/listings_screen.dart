import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_renting_group1/core/models/filter_options.dart';
import 'package:room_renting_group1/core/models/listing.dart';
import 'package:room_renting_group1/features/listings/state/filter_state.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../widgets/listing_card.dart';
import '../widgets/listing_filter_bottom_sheet.dart';
import '../state/listing_state.dart';
import 'single_listing_screen.dart';
import '../widgets/listing_address_search.dart';

class ListingsScreen extends ConsumerStatefulWidget {
  const ListingsScreen({super.key});

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen> {
  late final TextEditingController addressController;

  @override
  void initState() {
    super.initState();
    addressController = TextEditingController();
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsyncValue = ref.watch(listingsProvider);
    final theme = ShadTheme.of(context);
    final filterOptions = ref.watch(filterOptionsProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && addressController.text != (filterOptions.city ?? '')) {
        addressController.text = filterOptions.city ?? '';
      }
    });

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
                    controller: addressController,
                    placeholder: const Text('Search city'),
                    onPressed: () async {
                      final selectedAddress = await showDialog<AddressResult?>(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          // Pass the new parameter here
                          return const AddressSearchDialog(
                            searchOnlyCities: true,
                          );
                        },
                      );

                      if (selectedAddress != null && mounted) {
                        final currentFilters = ref.read(filterOptionsProvider);
                        // Creates a copy of the current filters, only changing the city
                        final newFilters = currentFilters.copyWith(
                          city: selectedAddress.cityName,
                        );
                        print(
                          'Updating filters from screen with city: ${newFilters.city}',
                        );

                        // Updates the central state, which triggers a data refetch
                        ref
                            .read(filterOptionsProvider.notifier)
                            .updateFilters(newFilters);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8.0),

                if (filterOptions.city != null &&
                    filterOptions.city!.isNotEmpty) ...[
                  ShadButton.ghost(
                    onPressed: () {
                      addressController.clear();
                      final currentFilters = ref.read(filterOptionsProvider);
                      // Manually create a new FilterOptions object
                      final newFilters = FilterOptions(
                        // Copy all existing values
                        priceRange: currentFilters.priceRange,
                        type: currentFilters.type,
                        surfaceRange: currentFilters.surfaceRange,
                        maxTransportDist: currentFilters.maxTransportDist,
                        maxHessoDist: currentFilters.maxHessoDist,
                        amenities: currentFilters.amenities,
                        availableFrom: currentFilters.availableFrom,
                        availableTo: currentFilters.availableTo,
                        // Explicitly set city to null
                        city: null,
                      );
                      ref
                          .read(filterOptionsProvider.notifier)
                          .updateFilters(newFilters);
                    },
                    child: const Icon(LucideIcons.x, size: 16),
                  ),
                  const SizedBox(width: 8.0),
                ],

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
