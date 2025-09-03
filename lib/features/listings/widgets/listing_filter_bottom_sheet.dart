// lib/features/listings/widgets/filter_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:room_renting_group1/core/models/listing.dart'; // For amenitiesLabels

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // State variables for filters
  RangeValues _priceRange = const RangeValues(500, 2500);
  String? _selectedType;
  RangeValues _surfaceRange = const RangeValues(20, 100);
  double _maxTransportDist = 5;
  double _maxHessoDist = 5;
  final RangeValues _numRoomsRange = const RangeValues(1, 5);
  final Map<String, bool> _amenities = {
    "is_furnished": false,
    "wifi_incl": false,
    "charges_incl": false,
    "car_park": false,
  };

  // Helper method to build a section with a title
  Widget _buildFilterSection(String title, Widget child) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      width: double.infinity,
      // Use a fraction of the screen height
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: theme.textTheme.h4),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Price Filter ---
                  _buildFilterSection(
                    'Price Range (CHF ${_priceRange.start.round()} - ${_priceRange.end.round()})',
                    RangeSlider(
                      min: 0,
                      max: 5000,
                      values: _priceRange,
                      onChanged: (values) =>
                          setState(() => _priceRange = values),
                    ),
                  ),

                  // --- Type Filter ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildFilterSection(
                          'Type',
                          ShadRadioGroup<String>(
                            initialValue: _selectedType,
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value;
                              });
                            },
                            items: const [
                              ShadRadio<String>(
                                value: 'Apartment',
                                label: Text('Apartment'),
                              ),
                              SizedBox(height: 8),
                              ShadRadio<String>(
                                value: 'Room',
                                label: Text('Room'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),

                  // --- Surface Filter ---
                  _buildFilterSection(
                    'Surface (${_surfaceRange.start.round()} - ${_surfaceRange.end.round()} m²)',
                    RangeSlider(
                      values: _surfaceRange,
                      max: 100,
                      divisions: 5,
                      labels: RangeLabels(
                        _surfaceRange.start.round().toString(),
                        _surfaceRange.end.round().toString(),
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _surfaceRange = values;
                        });
                      },
                    ),
                  ),

                  // --- Proximity Filters ---
                  _buildFilterSection(
                    'Max Distance to HES-SO (${_maxHessoDist.toStringAsFixed(1)} km)',
                    ShadSlider(
                      min: 0,
                      max: 10,
                      initialValue: _maxHessoDist,
                      onChanged: (value) =>
                          setState(() => _maxHessoDist = value),
                    ),
                  ),
                  _buildFilterSection(
                    'Max Distance to Public Transport (${_maxTransportDist.toStringAsFixed(1)} km)',
                    ShadSlider(
                      min: 0,
                      max: 50,
                      initialValue: _maxTransportDist,
                      onChanged: (value) =>
                          setState(() => _maxTransportDist = value),
                    ),
                  ),

                  // --- Amenities ---
                  _buildFilterSection(
                    'Amenities',
                    Column(
                      children: _amenities.keys.map((key) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(Listing.amenitiesLabels[key] ?? key),
                            ShadSwitch(
                              value: _amenities[key]!,
                              onChanged: (value) {
                                setState(() {
                                  _amenities[key] = value;
                                });
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ShadButton(
            width: double.infinity,
            onPressed: () {
              // TODO: Pass filter data back to the listings screen
              print('Applying filters...');
              Navigator.of(context).pop();
            },
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}
