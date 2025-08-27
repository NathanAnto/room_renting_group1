// lib/features/listings/screens/create_listing_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/models/listing.dart';
import '../../../core/services/listing_service.dart';

// Sample data for dropdowns
const listingTypes = {
  'apartment': 'Apartment',
  'room': 'Room',
  'house': 'House',
};

const availabilityOptions = {
  'Available': 'Available',
  'Not Available': 'Not Available',
  'Pending': 'Pending',
  'Archived': 'Archived',
};

const allAmenities = {
  'air_conditioning': 'Air Conditioning',
  'in_unit_laundry': 'In-Unit Laundry',
  'internet': 'Internet',
  'fitness_center': 'Fitness Center',
  'secure_parking': 'Secure Parking',
  'terrace': 'Terrace',
};

class CreateListingScreen extends HookWidget {
  const CreateListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final listingService = useMemoized(() => ListingService());

    final titleController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final rentController = useTextEditingController();
    final cityController = useTextEditingController();
    final surfaceController = useTextEditingController();
    final addressController = useTextEditingController();

    final selectedType = useState<String?>(null);
    final selectedAvailability = useState<String?>(null);
    final selectedAmenities = useState<Map<String, bool>>({});

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('New Listing', style: TextStyle(color: Colors.white)),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ShadCard(
            width: 350,
            title: Text('Create a new listing', style: theme.textTheme.h4),
            description: const Text('Add a new room or apartment.'),
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ShadButton(
                  child: const Text('Create'),
                  onPressed: () async {
                    if (titleController.text.isEmpty ||
                        rentController.text.isEmpty ||
                        selectedType.value == null ||
                        selectedAvailability.value == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all required fields.')),
                      );
                      return;
                    }

                    final newListing = Listing(
                      ownerId: 'placeholder-user-id',
                      title: titleController.text,
                      description: descriptionController.text,
                      type: selectedType.value!,
                      rentPerMonth: double.tryParse(rentController.text) ?? 0.0,
                      predictedRentPerMonth: 0.0,
                      city: cityController.text,
                      addressLine: addressController.text,
                      lat: 73.2,
                      lng: 38.3,
                      surface: double.tryParse(surfaceController.text) ?? 0.0,
                      availability: selectedAvailability.value!,
                      amenities: selectedAmenities.value,
                      status: 'open',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    await listingService.addListing(newListing);

                    // Clear the form
                    titleController.clear();
                    descriptionController.clear();
                    rentController.clear();
                    cityController.clear();
                    surfaceController.clear();
                    addressController.clear();
                    selectedType.value = null;
                    selectedAvailability.value = null;
                    selectedAmenities.value = {};

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Listing created successfully!')),
                    );
                  },
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Title'),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: titleController,
                    placeholder: const Text('Title of your listing'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Description'),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    placeholder: const Text('A detailed description'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Rent per Month'),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: rentController,
                    placeholder: const Text('e.g., 1200.00'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text('City'),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: cityController,
                    placeholder: const Text('e.g., Sion'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Address'),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: addressController,
                    placeholder: const Text('e.g., Route de lausanne 3'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Surface (m²)'),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: surfaceController,
                    placeholder: const Text('e.g., 50'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text('Type'),
                  const SizedBox(height: 6),
                  ShadSelect<String>(
                    placeholder: const Text('Select'),
                    options: listingTypes.entries
                        .map((e) => ShadOption(value: e.key, child: Text(e.value)))
                        .toList(),
                    selectedOptionBuilder: (context, value) {
                      return Text(listingTypes[value]!);
                    },
                    onChanged: (value) {
                      selectedType.value = value;
                    },
                    initialValue: selectedType.value,
                  ),
                  const SizedBox(height: 16),
                  const Text('Availability'),
                  const SizedBox(height: 6),
                  ShadSelect<String>(
                    placeholder: const Text('Select'),
                    options: availabilityOptions.entries
                        .map((e) => ShadOption(value: e.key, child: Text(e.value)))
                        .toList(),
                    selectedOptionBuilder: (context, value) {
                      return Text(availabilityOptions[value]!);
                    },
                    onChanged: (value) {
                      selectedAvailability.value = value;
                    },
                    initialValue: selectedAvailability.value,
                  ),
                  const SizedBox(height: 16),
                  const Text('Amenities'),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: allAmenities.entries.map((amenity) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            ShadSwitch(
                              value: selectedAmenities.value[amenity.key] ?? false,
                              onChanged: (bool value) {
                                selectedAmenities.value = {
                                  ...selectedAmenities.value,
                                  amenity.key: value,
                                };
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(amenity.value),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}