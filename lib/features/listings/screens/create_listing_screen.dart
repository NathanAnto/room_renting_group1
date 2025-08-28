// lib/features/listings/screens/create_listing_screen.dart

import 'dart:convert'; // Import for JSON decoding
import 'dart:io';
import 'dart:async'; // Required for the Timer
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http; // Import the http package
import '../../../core/models/listing.dart';
import '../../../core/services/listing_service.dart';

// A simple class to hold parsed address data
class AddressResult {
  final String displayName;
  final double lat;
  final double lng;

  AddressResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  factory AddressResult.fromJson(Map<String, dynamic> json) {
    return AddressResult(
      displayName: json['display_name'] ?? 'N/A',
      lat: double.parse(json['lat'] ?? '0.0'),
      lng: double.parse(json['lon'] ?? '0.0'),
    );
  }
}

// Function to search for addresses using Nominatim API
Future<List<AddressResult>> _searchAddresses(String query) async {
  if (query.isEmpty) {
    return [];
  }

  // Build the Nominatim API URL with search parameters
  final url = Uri.https('nominatim.openstreetmap.org', '/search', {
    'q': query,
    'format': 'json',
    'addressdetails': '1',
    'limit': '10',
    'countrycodes': 'ch',
  });

  // Add User-Agent header as required by Nominatim usage policy
  final response = await http.get(
    url,
    headers: {'User-Agent': 'PropertyFinderApp/1.0'},
  );

  if (response.statusCode == 200) {
    // Parse the JSON response
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => AddressResult.fromJson(json)).toList();
  } else {
    print('Error searching addresses: ${response.statusCode}');
    return [];
  }
}

// Sample data for dropdowns
const listingTypes = {'apartment': 'Apartment', 'room': 'Room'};

const availabilityOptions = {'published': 'Published', 'archived': 'Archived'};

const valueAmenities = {
  "type": "Type",
  "surface_m2": "Surface (m²)",
  "dist_public_transport_km": "Distance to Public Transport (km)",
  "proxim_hesso_km": "Proximity to HES-SO (km)",
  "num_rooms": "Number of Rooms",
};

const boolAmenities = {
  "is_furnished": "Furnished",
  "wifi_incl": "WiFi Included",
  "charges_incl": "Charges Included",
  "car_park": "Car Park",
};

class CreateListingScreen extends HookWidget {
  const CreateListingScreen({super.key});

  Future<List<String>> _uploadImages(
    String listingId,
    List<PlatformFile> files,
  ) async {
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

    final selectedType = useState<String?>(null);
    final selectedAvailability = useState<String?>(null);
    final amenityValues = useState<Map<String, dynamic>>({});
    final selectedAmenities = useState<Map<String, bool>>({});
    final selectedFiles = useState<List<PlatformFile>>([]);
    final addressController = useTextEditingController();
    final lat = useState<double>(0.0);
    final lng = useState<double>(0.0);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ShadCard(
            width: 350,
            title: Text('Create a new listing', style: theme.textTheme.h4),
            description: const Text(
              'Add a new room or apartment to your database.',
            ),
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ShadButton(
                  child: const Text('Create'),
                  onPressed: () async {
                    if (titleController.text.isEmpty ||
                        rentController.text.isEmpty ||
                        selectedType.value == null ||
                        selectedAvailability.value == null ||
                        addressController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields.'),
                        ),
                      );
                      return;
                    }

                    final listingId = const Uuid().v4();
                    List<String> imageUrls = await _uploadImages(
                      listingId,
                      selectedFiles.value,
                    );

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
                      lat: lat.value,
                      lng: lng.value,
                      surface: double.tryParse(surfaceController.text) ?? 0.0,
                      availability: selectedAvailability.value!,
                      amenities: {
                        ...amenityValues.value,
                        ...selectedAmenities.value,
                      },
                      status: 'open',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      images: imageUrls,
                    );
                    await listingService.addListing(newListing);

                    titleController.clear();
                    descriptionController.clear();
                    rentController.clear();
                    cityController.clear();
                    surfaceController.clear();
                    selectedType.value = null;
                    selectedAvailability.value = null;
                    amenityValues.value = {};
                    selectedAmenities.value = {};
                    selectedFiles.value = [];
                    addressController.clear();
                    lat.value = 0.0;
                    lng.value = 0.0;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Listing created successfully!'),
                      ),
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
                    placeholder: const Text('Start typing an address'),
                    onPressed: () async {
                      final selectedAddress = await showDialog<AddressResult?>(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return const _AddressSearchDialog();
                        },
                      );

                      if (selectedAddress != null) {
                        addressController.text = selectedAddress.displayName;
                        lat.value = selectedAddress.lat;
                        lng.value = selectedAddress.lng;
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  const Text('Availability'),
                  const SizedBox(height: 6),
                  ShadSelect<String>(
                    placeholder: const Text('Select'),
                    options: availabilityOptions.entries
                        .map(
                          (e) => ShadOption(value: e.key, child: Text(e.value)),
                        )
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
                  const Text(
                    'Amenities',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),

                  const SizedBox(height: 16),
                  const Text('Type'),
                  ShadSelect<String>(
                    placeholder: const Text('Select'),
                    options: listingTypes.entries
                        .map(
                          (e) => ShadOption(value: e.key, child: Text(e.value)),
                        )
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

                  const Text('Surface (m²)'),
                  const SizedBox(height: 6),
                  ShadInput(
                    controller: surfaceController,
                    placeholder: const Text('e.g., 50'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 16),
                  const Text('Distance to Public Transport (km)'),
                  const SizedBox(height: 6),
                  ShadInput(
                    placeholder: const Text('e.g., 0.5'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      amenityValues.value = {
                        ...amenityValues.value,
                        'dist_public_transport_km':
                            double.tryParse(value) ?? 0.0,
                      };
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Proximity to HES-SO (km)'),
                  const SizedBox(height: 6),
                  ShadInput(
                    placeholder: const Text('e.g., 1.2'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      amenityValues.value = {
                        ...amenityValues.value,
                        'proxim_hesso_km': double.tryParse(value) ?? 0.0,
                      };
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Number of Rooms'),
                  const SizedBox(height: 6),
                  ShadInput(
                    placeholder: const Text('e.g., 3'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      amenityValues.value = {
                        ...amenityValues.value,
                        'num_rooms': int.tryParse(value) ?? 0,
                      };
                    },
                  ),
                  const SizedBox(height: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: boolAmenities.entries.map((amenity) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            ShadSwitch(
                              value:
                                  selectedAmenities.value[amenity.key] ?? false,
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
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(allowMultiple: true, type: FileType.image);
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

class _AddressSearchDialog extends HookWidget {
  const _AddressSearchDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final searchResults = useState<List<AddressResult>>([]);
    final isLoading = useState<bool>(false);
    final hasSearched = useState<bool>(
      false,
    ); // Track if a search has been attempted
    final timer = useRef<Timer?>(null);

    // Clean up the timer when the widget is disposed to prevent memory leaks
    useEffect(() {
      return () => timer.value?.cancel();
    }, const []);

    Future<void> _performSearch(String query) async {
      // Don't search for very short queries to save API calls
      if (query.length < 3) {
        searchResults.value = [];
        isLoading.value = false;
        hasSearched.value = true;
        return;
      }
      isLoading.value = true;
      hasSearched.value = true; // Mark that a search has been attempted
      final results = await _searchAddresses(query);
      // Ensure the widget is still in the tree before updating state
      if (context.mounted) {
        searchResults.value = results;
        isLoading.value = false;
      }
    }

    // This function debounces the search. It starts a timer and only
    // calls the search function after the user has stopped typing.
    void onSearchChanged(String query) {
      if (timer.value?.isActive ?? false) timer.value!.cancel();
      timer.value = Timer(const Duration(milliseconds: 500), () {
        _performSearch(query);
      });
    }

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShadInput(
              controller: searchController,
              placeholder: const Text('Search for an address'),
              onChanged: onSearchChanged, // Use the new debounced function
            ),
            const SizedBox(height: 16),
            // Constrain the height to prevent the dialog from resizing awkwardly
            SizedBox(
              height: 300,
              child: Builder(
                builder: (context) {
                  if (isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  // Show a helpful message before the first search
                  if (!hasSearched.value) {
                    return const Center(
                      child: Text('Start typing to find an address.'),
                    );
                  }
                  if (searchResults.value.isEmpty) {
                    return const Center(child: Text('No results found.'));
                  }
                  // The ListView is now safely constrained
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchResults.value.length,
                    itemBuilder: (context, index) {
                      final result = searchResults.value[index];
                      return ListTile(
                        title: Text(result.displayName),
                        onTap: () {
                          Navigator.pop(context, result);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            ShadButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
