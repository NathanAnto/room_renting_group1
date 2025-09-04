// features/listings/widgets/address_search_field.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:room_renting_group1/core/models/listing.dart';

class AddressSearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<OsmPlace> onPlaceSelected;
  final String? Function(String?)? validator;
  final String label;

  const AddressSearchField({
    Key? key,
    required this.controller,
    required this.onPlaceSelected,
    this.validator,
    this.label = 'Adresse *',
  }) : super(key: key);

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  List<OsmPlace> _suggestions = [];
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onInputChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      if (q.trim().length < 3) {
        setState(() => _suggestions = []);
        return;
      }
      try {
        final items = await _searchNominatim(q);
        if (mounted) setState(() => _suggestions = items);
      } catch (_) {
        if (mounted) setState(() => _suggestions = []);
      }
    });
  }

  Future<List<OsmPlace>> _searchNominatim(String q) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'q': q,
      'addressdetails': '1',
      'limit': '6',
      'countrycodes': 'ch',
    });
    final res = await http.get(
      uri,
      headers: {'User-Agent': 'RoomRentingApp/1.0 (contact: app@example.com)'},
    );
    if (res.statusCode != 200) return [];
    final data = json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return data.map((e) => OsmPlace.fromJson(e)).toList();
  }

  void _selectPlace(OsmPlace p) {
    // Hide suggestions and notify the parent widget of the selection.
    // The parent is responsible for updating the text controller.
    setState(() => _suggestions = []);
    widget.onPlaceSelected(p);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.place_outlined),
          ),
          validator: widget.validator,
          onChanged: _onInputChanged,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final p = _suggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(p.displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(p.city ?? p.town ?? p.village ?? ''),
                  onTap: () => _selectPlace(p),
                );
              },
            ),
          ),
      ],
    );
  }
}
