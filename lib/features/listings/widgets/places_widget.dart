// lib/features/listings/widgets/nearby_places_list.dart
import 'package:flutter/material.dart';
import '../../../core/utils/places_api.dart';

class NearbyPlacesList extends StatelessWidget {
  final double lat;
  final double lon;
  final int radiusMeters;
  final int limit;

  const NearbyPlacesList({
    super.key,
    required this.lat,
    required this.lon,
    this.radiusMeters = 500,
    this.limit = 10,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchNearbyPlaces(
        lat,
        lon,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _Skeleton();
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.error_outline),
                const SizedBox(width: 8),
                Expanded(child: Text('Impossible de charger les lieux à proximité.\n${snapshot.error}')),
              ],
            ),
          );
        }
        final places = snapshot.data ?? [];
        if (places.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text('Aucun lieu à proximité.'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  Icon(Icons.place_outlined),
                  SizedBox(width: 8),
                  Text(
                    'À proximité',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: places.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = places[index];
                final trailing = (p.distanceMeters != null)
                    ? Text('${p.distanceMeters!.toStringAsFixed(0)} m')
                    : null;

                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(p.address, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: trailing,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // petit placeholder pendant le chargement
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: List.generate(4, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const CircleAvatar(radius: 12),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
