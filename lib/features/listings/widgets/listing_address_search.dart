// lib/features/listings/widgets/listing_address_search.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:room_renting_group1/core/models/listing.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:room_renting_group1/core/services/listing_service.dart'; // Adjust import path as needed

// This provider exposes your ListingService instance
final listingServiceProvider = Provider((ref) => ListingService());

class AddressSearchDialog extends ConsumerStatefulWidget {
  final bool searchOnlyCities;

  const AddressSearchDialog({super.key, this.searchOnlyCities = false});

  @override
  ConsumerState<AddressSearchDialog> createState() =>
      _AddressSearchDialogState();
}

class _AddressSearchDialogState extends ConsumerState<AddressSearchDialog> {
  late final TextEditingController _controller;
  Timer? _debounce;
  var _isLoading = false;
  List<AddressResult> _results = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // Add a listener to trigger the search with debouncing
    _controller.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _performSearch(_controller.text);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _performSearch(String query) async {
    // Don't search for very short strings
    if (query.length < 3) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isLoading = true);

    final service = ref.read(listingServiceProvider);
    final results = await service.searchAddresses(
      query,
      widget.searchOnlyCities,
    );

    // Ensure the widget is still mounted before updating the state
    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Search Address'),
      child: SizedBox(
        height: 400, // Give the dialog a fixed height
        width: 350, // and width
        child: Column(
          children: [
            ShadInput(
              controller: _controller,
              placeholder: const Text('Type an address or city...'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                  ? const Center(child: Text('No results found.'))
                  : Material(
                      color: Colors.transparent, // So it blends with the dialog
                      child: ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final result = _results[index];
                          return ListTile(
                            title: Text(result.displayName),
                            onTap: () {
                              // Pop the dialog and return the selected result
                              Navigator.of(context).pop(result);
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
