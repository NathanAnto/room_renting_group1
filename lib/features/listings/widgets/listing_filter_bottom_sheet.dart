import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:room_renting_group1/core/models/listing.dart';
import '../../../core/models/filter_options.dart';
import '../state/filter_state.dart';

// --- STYLE CONSTANTS ---
const Color primaryBlue = Color(0xFF0D47A1);
const Color lightGreyBackground = Color(0xFFF8F9FA);
const Color darkTextColor = Color(0xFF343A40);

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  // Local state variables for filters
  late RangeValues _priceRange;
  DateTime? _availableFrom;
  DateTime? _availableTo;
  String? _selectedCity;
  String? _selectedType;
  late RangeValues _surfaceRange;
  late double _maxTransportDist;
  late double _maxHessoDist;
  late Map<String, bool> _amenities;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    final currentFilters = ref.read(filterOptionsProvider);
    _priceRange = currentFilters.priceRange ?? const RangeValues(500, 2500);
    _availableFrom = currentFilters.availableFrom;
    _availableTo = currentFilters.availableTo;
    _selectedCity = currentFilters.city;
    _selectedType = currentFilters.type;
    _surfaceRange = currentFilters.surfaceRange ?? const RangeValues(20, 100);
    _maxTransportDist = currentFilters.maxTransportDist ?? 1.0;
    _maxHessoDist = currentFilters.maxHessoDist ?? 5.0;
    _amenities = Map<String, bool>.from(currentFilters.amenities ??
        {
          "is_furnished": false,
          "wifi_incl": false,
          "charges_incl": false,
          "car_park": false,
        });
  }

  void _resetToDefaults() {
    setState(() {
      final currentFilters = ref.read(filterOptionsProvider);
      _priceRange = const RangeValues(500, 2500);
      _availableFrom = null;
      _availableTo = null;
      _selectedCity = currentFilters.city; // Keep city from main screen
      _selectedType = null;
      _surfaceRange = const RangeValues(20, 100);
      _maxTransportDist = 1.0;
      _maxHessoDist = 5.0;
      _amenities = {
        "is_furnished": false,
        "wifi_incl": false,
        "charges_incl": false,
        "car_park": false,
      };
    });
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart ? (_availableFrom ?? now) : (_availableTo ?? _availableFrom ?? now);
    final firstDate = isStart ? now : (_availableFrom ?? now);
    
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _availableFrom = pickedDate;
          // Ensure end date is not before start date
          if (_availableTo != null && _availableTo!.isBefore(_availableFrom!)) {
            _availableTo = null;
          }
        } else {
          _availableTo = pickedDate;
        }
      });
    }
  }

  Widget _buildFilterSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: darkTextColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        child,
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: lightGreyBackground,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
              ),
              TextButton(
                onPressed: _resetToDefaults,
                child: const Text('Reset', style: TextStyle(color: darkTextColor)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: primaryBlue,
                  thumbColor: primaryBlue,
                  inactiveTrackColor: primaryBlue.withOpacity(0.2),
                  valueIndicatorColor: primaryBlue,
                  valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                  overlayColor: primaryBlue.withOpacity(0.1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSection(
                      'Price Range (CHF ${_priceRange.start.round()} - ${_priceRange.end.round()})',
                      RangeSlider(
                        min: 0,
                        max: 5000,
                        divisions: 50,
                        values: _priceRange,
                        labels: RangeLabels('CHF ${_priceRange.start.round()}', 'CHF ${_priceRange.end.round()}'),
                        onChanged: (values) => setState(() => _priceRange = values),
                      ),
                    ),
                    _buildFilterSection(
                      'Reservation Dates',
                      Row(
                        children: [
                          Expanded(child: _buildDateButton(context, isStart: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDateButton(context, isStart: false)),
                        ],
                      ),
                    ),
                    _buildFilterSection(
                      'Type',
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildTypeChip('entire_home', 'Entire Home'),
                          const SizedBox(width: 12),
                          _buildTypeChip('room', 'Room'),
                        ],
                      ),
                    ),
                    _buildFilterSection(
                      'Surface (${_surfaceRange.start.round()} - ${_surfaceRange.end.round()} m²)',
                      RangeSlider(
                        values: _surfaceRange,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        labels: RangeLabels('${_surfaceRange.start.round()} m²', '${_surfaceRange.end.round()} m²'),
                        onChanged: (values) => setState(() => _surfaceRange = values),
                      ),
                    ),
                    _buildFilterSection(
                      'Max Distance to HES-SO (${_maxHessoDist.toStringAsFixed(1)} km)',
                      Slider(
                        min: 0,
                        max: 10,
                        value: _maxHessoDist,
                        onChanged: (value) => setState(() => _maxHessoDist = value),
                      ),
                    ),
                    _buildFilterSection(
                      'Max Distance to Public Transport (${_maxTransportDist.toStringAsFixed(1)} km)',
                      Slider(
                        min: 0,
                        max: 2,
                        value: _maxTransportDist,
                        onChanged: (value) => setState(() => _maxTransportDist = value),
                      ),
                    ),
                    _buildFilterSection(
                      'Amenities',
                      Column(
                        children: _amenities.keys.map((key) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(Listing.amenitiesLabels[key] ?? key, style: const TextStyle(fontSize: 15, color: darkTextColor)),
                              Switch(
                                value: _amenities[key]!,
                                onChanged: (value) => setState(() => _amenities[key] = value),
                                activeColor: primaryBlue,
                                activeTrackColor: primaryBlue.withOpacity(0.5),
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
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                final newFilters = FilterOptions(
                  priceRange: _priceRange,
                  availableFrom: _availableFrom,
                  availableTo: _availableTo,
                  city: _selectedCity,
                  type: _selectedType,
                  surfaceRange: _surfaceRange,
                  maxTransportDist: _maxTransportDist,
                  maxHessoDist: _maxHessoDist,
                  amenities: _amenities,
                );
                ref.read(filterOptionsProvider.notifier).updateFilters(newFilters);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Apply Filters',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label) {
    final isSelected = _selectedType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedType = value;
          } else {
            _selectedType = null; // Optional: allow deselecting
          }
        });
      },
      selectedColor: primaryBlue,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : darkTextColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDateButton(BuildContext context, {required bool isStart}) {
    final formatter = DateFormat('d MMM yyyy');
    final date = isStart ? _availableFrom : _availableTo;
    final labelText = isStart ? 'From' : 'To';
    final buttonText = date != null ? formatter.format(date) : 'Select date';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: () => _selectDate(context, isStart: isStart),
          style: OutlinedButton.styleFrom(
            foregroundColor: darkTextColor,
            side: const BorderSide(color: Colors.grey),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(buttonText),
              const Icon(Icons.calendar_today, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}