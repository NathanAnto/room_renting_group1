// lib/features/listings/screens/single_listing_screen.dart

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/listing.dart';
import '../widgets/transport_widget.dart';


class SingleListingScreen extends StatelessWidget {
  final Listing listing;

  const SingleListingScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(listing.title),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Slideshow (Full width)
            if (listing.images.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  height: 250.0,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  aspectRatio: 16 / 9,
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enableInfiniteScroll: true,
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  viewportFraction: 1.0, // Make images full width
                ),
                items: listing.images.map((imageUrl) {
                  return Builder(
                    builder: (BuildContext context) {
                      return CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      );
                    },
                  );
                }).toList(),
              )
            else
              Container(
                height: 250,
                color: theme.colorScheme.primary,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),

            // Listing Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    style: theme.textTheme.h4.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${listing.city} - ${listing.addressLine}',
                    style: theme.textTheme.muted,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.payments,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CHF ${listing.rentPerMonth.toStringAsFixed(2)} / month',
                        style: theme.textTheme.p.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.square_foot,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text('${listing.surface.toStringAsFixed(0)} m²'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Description',
                    style: theme.textTheme.h4.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(listing.description),
                  const SizedBox(height: 24),

                  Text(
                    'Distance to Public Transport (km)',
                    style: theme.textTheme.h4.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(listing.distanceToPublicTransportKm.toStringAsFixed(2)),
                  const SizedBox(height: 24),

                  Text(
                    'Proximity to HES-SO (km)',
                    style: theme.textTheme.h4.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(listing.proximHessoKm.toStringAsFixed(2)),
                  const SizedBox(height: 24),

                  Text(
                    'Number of rooms',
                    style: theme.textTheme.h4.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(listing.numRooms.toString()),
                  const SizedBox(height: 24),
                  Text(
                    'Amenities',
                    style: theme.textTheme.h4.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: listing.amenities.entries
                        .where((entry) => entry.value == true)
                        .map(
                          (entry) => ShadBadge(
                            child: Text(
                              Listing.amenitiesLabels[entry.key].toString(),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 48),
                  Center(
                    child: ShadButton(
                      onPressed: () {
                        // TODO: Implement contact host logic
                        print('Contacting host for ${listing.title}');
                      },
                      child: const Text('Contact Host'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            StudentListingItinerary(listing: listing),
          ],
        ),
      ),
    );
  }
}
