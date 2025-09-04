import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_renting_group1/core/models/filter_options.dart';
import 'package:room_renting_group1/core/models/listing.dart';
import 'package:room_renting_group1/features/listings/state/filter_state.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../widgets/address_search_field.dart';
import '../widgets/listing_card.dart';
import '../widgets/listing_filter_bottom_sheet.dart';
import '../state/listing_state.dart';
import 'single_listing_screen.dart';

// --- STYLE CONSTANTS ---
const Color primaryBlue = Color(0xFF0D47A1);
const Color lightGreyBackground = Color(0xFFF8F9FA);
const Color lightTextColor = Color(0xFF6C757D);
const Color inputBorderColor = Color(0xFFDEE2E6);

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

  // Helper for a consistent input field style
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: lightTextColor),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: inputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: inputBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsyncValue = ref.watch(listingsProvider);
    final filterOptions = ref.watch(filterOptionsProvider);

    // Syncs the text controller with the filter state from Riverpod
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && addressController.text != (filterOptions.city ?? '')) {
        addressController.text = filterOptions.city ?? '';
      }
    });

    return Scaffold(
      backgroundColor: lightGreyBackground,
      appBar: AppBar(
        backgroundColor: lightGreyBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: primaryBlue,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(filterOptions),
          Expanded(
            child: listingsAsyncValue.when(
              data: (listings) {
                if (listings.isEmpty) {
                  return const Center(
                    child: Text(
                      'No listings match your criteria.',
                      style: TextStyle(color: lightTextColor, fontSize: 16),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
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
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: primaryBlue)),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading listings: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(FilterOptions filterOptions) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: AddressSearchField(
              controller: addressController,
              // **FIX**: Use the 'decoration' parameter instead of 'label'.
              decoration: _inputDecoration('Search for a city...'),
              onPlaceSelected: (OsmPlace selectedPlace) {
                final cityName = selectedPlace.city ??
                    selectedPlace.town ??
                    selectedPlace.displayName.split(',').first;
                
                final newFilters = ref.read(filterOptionsProvider).copyWith(city: cityName);

                ref.read(filterOptionsProvider.notifier).updateFilters(newFilters);
              },
            ),
          ),
          const SizedBox(width: 8.0),
          if (filterOptions.city != null && filterOptions.city!.isNotEmpty)
            ShadButton.ghost(
              onPressed: () {
                addressController.clear();
                final newFilters = filterOptions.copyWith(city: null);
                ref.read(filterOptionsProvider.notifier).updateFilters(newFilters);
              },
              child: const Icon(LucideIcons.x, size: 20),
            ),
          ShadButton.secondary(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
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
    );
  }
}