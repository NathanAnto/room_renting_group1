// lib/core/models/filter_options.dart
import 'package:flutter/material.dart';

class FilterOptions {
  final RangeValues? priceRange;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final String? city;
  final String? type;
  final RangeValues? surfaceRange;
  final double? maxTransportDist;
  final double? maxHessoDist;
  final Map<String, bool>? amenities;

  FilterOptions({
    this.priceRange,
    this.availableFrom,
    this.availableTo,
    this.city,
    this.type,
    this.surfaceRange,
    this.maxTransportDist,
    this.maxHessoDist,
    this.amenities,
  });

  /// Creates an instance of FilterOptions with all values reset to their defaults.
  factory FilterOptions.initial() {
    return FilterOptions(
      priceRange: null,
      availableFrom: null,
      availableTo: null,
      city: null,
      type: null,
      surfaceRange: null,
      maxTransportDist: null,
      maxHessoDist: null,
      amenities: {
        "is_furnished": false,
        "wifi_incl": false,
        "charges_incl": false,
        "car_park": false,
      },
    );
  }
  
  FilterOptions copyWith({
    RangeValues? priceRange,
    DateTime? availableFrom,
    DateTime? availableTo,
    String? city,
    String? type,
    RangeValues? surfaceRange,
    double? maxTransportDist,
    double? maxHessoDist,
    Map<String, bool>? amenities,
  }) {
    return FilterOptions(
      priceRange: priceRange ?? this.priceRange,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      city: city ?? this.city,
      type: type ?? this.type,
      surfaceRange: surfaceRange ?? this.surfaceRange,
      maxTransportDist: maxTransportDist ?? this.maxTransportDist,
      maxHessoDist: maxHessoDist ?? this.maxHessoDist,
      amenities: amenities ?? this.amenities,
    );
  }
}