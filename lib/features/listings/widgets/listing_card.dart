// lib/features/listings/widgets/listing_card.dart
import 'package:flutter/material.dart';
import 'package:room_renting_group1/core/models/listing.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback? onViewDetails;
  final VoidCallback? onContactHost;
  final bool showEditButton;
  final VoidCallback? onEdit;
  final bool showDeleteButton;
  final VoidCallback? onDelete;

  const ListingCard({
    super.key,
    required this.listing,
    this.onViewDetails,
    this.onContactHost,
    this.showEditButton = false,
    this.onEdit,
    this.showDeleteButton = false,
    this.onDelete, 
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    
    return ShadCard(
      width: double.infinity,
      title: Text(
        listing.title,
        style: theme.textTheme.h4,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      description: Text(
        listing.addressLine,
        style: theme.textTheme.muted,
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ShadButton.outline(
            onPressed: onViewDetails,
            child: const Text('View Details'),
          ),
          const SizedBox(width: 8),
          if (showEditButton) ...[
            ShadButton.secondary(
              onPressed: onEdit,
              child: const Text('Edit'),
            ),
            const SizedBox(width: 8),
          ],
          if (showDeleteButton) ...[
            ShadButton.destructive(
              onPressed: onDelete,
              child: const Text('Delete'),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageCarousel(listing.images, theme),
          const SizedBox(height: 12),
          _buildPriceSection(listing.rentPerMonth, theme),
          const SizedBox(height: 8),
          _buildAmenitiesBadges(listing.amenities),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images, ShadThemeData theme) {
    if (images.isEmpty) {
      return Container(
        height: 200,
        color: theme.colorScheme.muted,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.white),
        ),
      );
    }

    return CarouselSlider(
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
      items: images.map((imageUrl) => _buildCarouselItem(imageUrl, theme)).toList(),
    );
  }

  Widget _buildCarouselItem(String imageUrl, ShadThemeData theme) {
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
  }

  Widget _buildPriceSection(double price, ShadThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'CHF ${price.toStringAsFixed(2)} / month',
        style: theme.textTheme.p.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildAmenitiesBadges(Map<String, bool> amenities) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: [
        ...amenities.entries
            .where((entry) => entry.value == true)
            .map((entry) => ShadBadge(child: Text(Listing.amenitiesLabels[entry.key].toString()))),
      ],
    );
  }
}