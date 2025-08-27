import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/listing.dart';
import '../../../core/services/listing_service.dart';


// Sample data for dropdowns
const listingTypes = {
  'apartment': 'Apartment',
  'room': 'Room',
  'house': 'House',
};

const availabilityOptions = {
  'Immediately': 'Immediately',
  '2 Weeks': '2 Weeks',
  '1 Month': '1 Month',
};

const allAmenities = {
  'air_conditioning': 'Air Conditioning',
  'in_unit_laundry': 'In-Unit Laundry',
  'internet': 'Internet',
  'fitness_center': 'Fitness Center',
  'pool': 'Pool',
  'outdoor_lounge': 'Outdoor Lounge Area',
  'secure_parking': 'Secure Parking',
  'garden': 'Garden',
  'terrace': 'Terrace',
};


class CreateListingScreen extends HookWidget {
  const CreateListingScreen({super.key});

  // Function to upload files to Firebase Storage and get their URLs
  Future<List<String>> _uploadImages(String listingId, List<PlatformFile> files) async {
    final storage = FirebaseStorage.instance;
    List<String> downloadUrls = [];

    for (var file in files) {
      final fileName = file.name;
      final path = 'listings/$listingId/$fileName';
      final fileRef = storage.ref().child(path);

      try {
        await fileRef.putData(file.bytes!);
        final url = await fileRef.getDownloadURL();
        downloadUrls.add(url);
      } catch (e) {
        print('Error uploading file: $e');
      }
    }
    return downloadUrls;
  }

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
    final selectedFiles = useState<List<PlatformFile>>([]);

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
            description: const Text('Add a new room or apartment to your database.'),
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

                    // Generate a unique ID for the new listing to use for the image path
                    final listingId = const Uuid().v4();

                    // Upload images to Firebase Storage first
                    List<String> imageUrls = await _uploadImages(listingId, selectedFiles.value);

                    final newListing = Listing(
                      id: listingId,
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
                      images: imageUrls,
                    );
                    await listingService.addListing(newListing);

                    // Clear the form and files
                    titleController.clear();
                    descriptionController.clear();
                    rentController.clear();
                    cityController.clear();
                    surfaceController.clear();
                    addressController.clear();
                    selectedType.value = null;
                    selectedAvailability.value = null;
                    selectedAmenities.value = {};
                    selectedFiles.value = [];

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
                  const SizedBox(height: 16),
                  const Text('Images'),
                  const SizedBox(height: 6),
                  ShadButton(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        allowMultiple: true,
                        type: FileType.image,
                      );
                      if (result != null) {
                        selectedFiles.value = result.files;
                      }
                    },
                    child: const Text('Select Images'),
                  ),
                  const SizedBox(height: 8),
                  if (selectedFiles.value.isNotEmpty)
                    Text(
                      'Selected files: ${selectedFiles.value.length}',
                      style: theme.textTheme.small,
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