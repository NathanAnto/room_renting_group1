// lib/core/models/filter_options.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterOptions {
  final String? city;
  final String? type;
  final double minRent;
  final double maxRent;
  final double maxPublicTransportDistance;
  final double maxProximHessoDistance;
  final List<String> amenities;

  FilterOptions({
    this.city,
    this.type,
    this.minRent = 0,
    this.maxRent = 5000,
    this.maxPublicTransportDistance = 10,
    this.maxProximHessoDistance = 20,
    this.amenities = const [],
  });

  FilterOptions copyWith({
    String? city,
    String? type,
    double? minRent,
    double? maxRent,
    double? maxPublicTransportDistance,
    double? maxProximHessoDistance,
    List<String>? amenities,
  }) {
    return FilterOptions(
      city: city ?? this.city,
      type: type ?? this.type,
      minRent: minRent ?? this.minRent,
      maxRent: maxRent ?? this.maxRent,
      maxPublicTransportDistance: maxPublicTransportDistance ?? this.maxPublicTransportDistance,
      maxProximHessoDistance: maxProximHessoDistance ?? this.maxProximHessoDistance,
      amenities: amenities ?? this.amenities,
    );
  }
}

class FilterOptionsNotifier extends StateNotifier<FilterOptions> {
  FilterOptionsNotifier() : super(FilterOptions());

  void updateCity(String? newCity) {
    state = state.copyWith(city: newCity);
  }

  void updateType(String? newType) {
    state = state.copyWith(type: newType);
  }

  void updateRentRange(double min, double max) {
    state = state.copyWith(minRent: min, maxRent: max);
  }
  
  void updateMaxRent(double maxRent) {
    state = state.copyWith(maxRent: maxRent);
  }

  void updatePublicTransportDistance(double distance) {
    state = state.copyWith(maxPublicTransportDistance: distance);
  }

  void updateProximHessoDistance(double distance) {
    state = state.copyWith(maxProximHessoDistance: distance);
  }

  void addAmenity(String amenity) {
    state = state.copyWith(amenities: [...state.amenities, amenity]);
  }

  void removeAmenity(String amenity) {
    final newAmenities = List<String>.from(state.amenities);
    newAmenities.remove(amenity);
    state = state.copyWith(amenities: newAmenities);
  }
}

final filterOptionsProvider =
    StateNotifierProvider<FilterOptionsNotifier, FilterOptions>((ref) {
  return FilterOptionsNotifier();
});