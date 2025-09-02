// lib/features/listings/screens/listings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
                child: ShadCard(
                  width: double.infinity,
                  title: Text(
                    listing.title,
                    style: theme.textTheme.h4,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  description: Text(
                    '${listing.city} - ${listing.addressLine}',
                    style: theme.textTheme.muted,
                  ),
                  footer: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ShadButton.outline(
                        onPressed: () {
                          // Navigate to the single listing screen, passing the listing object
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SingleListingScreen(listing: listing),
                            ),
                          );
                        },
                        child: const Text('View Details'),
                      ),
                      const SizedBox(width: 8),
                      ShadButton(
                        onPressed: () {
                          // TODO: Implement contact host functionality
                          print('Contact host for ${listing.title}');
                        },
                        child: const Text('Contact Host'),
                      ),
                    ],
                  ),
                  // Use the `child` parameter for the main card content.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Slideshow (Carousel)
                      if (listing.images.isNotEmpty)
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 200.0,
                            enlargeCenterPage: true,
                            autoPlay: true,
                            aspectRatio: 16 / 9,
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enableInfiniteScroll: true,
                            autoPlayAnimationDuration: const Duration(milliseconds: 800),
                            viewportFraction: 0.8,
                          ),
                          items: listing.images.map((imageUrl) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(Icons.error),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        )
                      else
                        Container(
                          height: 200,
                          color: theme.colorScheme.muted,
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 50, color: Colors.white),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'CHF ${listing.rentPerMonth.toStringAsFixed(2)} / month',
                          style: theme.textTheme.p.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: listing.amenities.entries
                            .where((entry) => entry.value is bool && entry.value == true)
                            .map((entry) => ShadBadge(child: Text(entry.key.replaceAll('_', ' '))))
                            .followedBy(listing.amenities.entries
                            .where((entry) => entry.value is num)
                            .map((entry) => ShadBadge(child: Text('${entry.key.replaceAll('_', ' ')}: ${entry.value}'))))
                            .toList(),
                      ),
                    ],
                  ),
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