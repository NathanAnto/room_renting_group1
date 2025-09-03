import 'package:flutter/material.dart';
import 'package:room_renting_group1/core/models/ListingAvailability.dart';
import 'package:room_renting_group1/core/models/listing.dart';
import 'package:room_renting_group1/core/services/listing_service.dart';
import 'package:room_renting_group1/features/listings/widgets/address_search_field.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class EditListingScreen extends StatefulWidget {
  final Listing listing;

  const EditListingScreen({
    super.key,
    required this.listing,
  });

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _listingService = ListingService();
  bool _saving = false;

  // Controllers
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _rentCtrl;
  late final TextEditingController _roomsCtrl;

  // State variables
  late String _status;
  late Map<String, bool> _amenities;
  late double _lat;
  late double _lng;
  late List<AvailabilityWindow> _windows;

  static const _statusValues = ['draft', 'active', 'paused', 'archived'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers and state from the listing object
    _titleCtrl = TextEditingController(text: widget.listing.title);
    _descCtrl = TextEditingController(text: widget.listing.description);
    _addressCtrl = TextEditingController(text: widget.listing.addressLine);
    _rentCtrl =
        TextEditingController(text: widget.listing.rentPerMonth.toStringAsFixed(0));
    _roomsCtrl = TextEditingController(text: widget.listing.numRooms.toString());
    _status = widget.listing.status;
    // Create a mutable copy of the amenities map
    _amenities = Map.from(widget.listing.amenities);
    _lat = widget.listing.lat;
    _lng = widget.listing.lng;
    _windows = List.from(widget.listing.availability.windows);
  }

  @override
  void dispose() {
    // Dispose all controllers
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _rentCtrl.dispose();
    _roomsCtrl.dispose();
    super.dispose();
  }

  String get _typeFromRooms {
    final n = int.tryParse(_roomsCtrl.text) ?? 0;
    return n <= 1 ? 'room' : 'entire_home';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    // Create an updated listing object
    final updatedListing = widget.listing.copyWith(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      addressLine: _addressCtrl.text.trim(),
      rentPerMonth: double.tryParse(_rentCtrl.text) ?? 0,
      numRooms: int.tryParse(_roomsCtrl.text) ?? 0,
      type: _typeFromRooms,
      status: _status,
      amenities: _amenities,
      lat: _lat,
      lng: _lng,
      availability: widget.listing.availability.copyWith(windows: _windows),
      updatedAt: DateTime.now(),
    );

    try {
      await _listingService.updateListing(updatedListing);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update listing: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Edit Listing'),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        centerTitle: true,
        actions: [
          ShadButton(
            onPressed: _saving ? null : _saveChanges,
            child: _saving
                ? const SizedBox.square(
                    dimension: 16, child: CircularProgressIndicator())
                : const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildTextField(_titleCtrl, 'Title'),
            const SizedBox(height: 16),
            _buildTextField(_descCtrl, 'Description', maxLines: 4),
            const SizedBox(height: 16),
            AddressSearchField(
              controller: _addressCtrl,
              onPlaceSelected: (place) {
                setState(() {
                  _addressCtrl.text = place.displayName;
                  _lat = place.lat;
                  _lng = place.lon;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    _rentCtrl,
                    'Price (CHF/month)',
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    _roomsCtrl,
                    'Number of Rooms',
                    isNumber: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDropdownStatus(),
            const SizedBox(height: 24),
            _buildAmenitiesSection(),
            const SizedBox(height: 24),
            _buildAvailabilitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ShadTheme.of(context).textTheme.p),
        const SizedBox(height: 8),
        ShadInput(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        ),
      ],
    );
  }

  Widget _buildDropdownStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: ShadTheme.of(context).textTheme.p),
        const SizedBox(height: 8),
        ShadSelect<String>(
          initialValue: _status,
          onChanged: (value) {
            if (value != null) {
              setState(() => _status = value);
            }
          },
          options: _statusValues
              .map((s) => ShadOption(value: s, child: Text(s)))
              .toList(),
          selectedOptionBuilder: (context, value) => Text(value),
          placeholder: const Text('Select a status'),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Amenities', style: ShadTheme.of(context).textTheme.h4),
        const SizedBox(height: 16),
        ..._amenities.keys.map((key) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
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
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _pickWindow() async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 3, 12, 31),
      helpText: 'Start date (inclusive)',
    );
    if (start == null) return;

    final end = await showDatePicker(
      context: context,
      initialDate: start.add(const Duration(days: 1)),
      firstDate: start.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 3, 12, 31),
      helpText: 'End date (exclusive)',
    );
    if (end == null) return;

    setState(() {
      final utcStart = DateTime.utc(start.year, start.month, start.day);
      final utcEnd = DateTime.utc(end.year, end.month, end.day);
      _windows.add(AvailabilityWindow(start: utcStart, end: utcEnd));
    });
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Availability Windows',
            style: ShadTheme.of(context).textTheme.h4),
        const SizedBox(height: 16),
        ShadButton.outline(
          onPressed: _pickWindow,
          child: const Text('Add Window'),
        ),
        const SizedBox(height: 16),
        if (_windows.isEmpty)
          const Text('No availability windows added yet.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _windows.asMap().entries.map((entry) {
              final index = entry.key;
              final window = entry.value;
              String fmt(DateTime d) =>
                  "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
              return Chip(
                label: Text("${fmt(window.start)} → ${fmt(window.end)}"),
                onDeleted: () {
                  setState(() {
                    _windows.removeAt(index);
                  });
                },
              );
            }).toList(),
          )
      ],
    );
  }
}

