// lib/features/listings/widgets/address_search_field.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:room_renting_group1/core/models/listing.dart';

// --- STYLE CONSTANTS ---
const Color primaryBlue = Color(0xFF0D47A1);
const Color darkTextColor = Color(0xFF343A40);
const Color inputBorderColor = Color(0xFFDEE2E6);

class AddressSearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<OsmPlace> onPlaceSelected;
  final String? Function(String?)? validator;
  final InputDecoration? decoration;
  
  const AddressSearchField({
    Key? key,
    required this.controller,
    required this.onPlaceSelected,
    this.validator,
    this.decoration,
  }) : super(key: key);

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  List<OsmPlace> _suggestions = [];
  Timer? _debounce;
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onInputChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      if (query.trim().length < 3) {
        if (mounted) setState(() => _suggestions = []);
        _updateOverlay();
        return;
      }
      try {
        final items = await _searchNominatim(query);
        if (mounted) {
          setState(() => _suggestions = items);
          _updateOverlay();
        }
      } catch (_) {
        if (mounted) {
          setState(() => _suggestions = []);
          _updateOverlay();
        }
      }
    });
  }

  Future<List<OsmPlace>> _searchNominatim(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'q': query,
      'addressdetails': '1',
      'limit': '5',
      'countrycodes': 'ch',
    });
    final res = await http.get(
      uri,
      headers: {'User-Agent': 'RoomRentingApp/1.0 (contact@yourapp.com)'},
    );
    if (res.statusCode != 200) return [];
    final data = json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return data.map((e) => OsmPlace.fromJson(e)).toList();
  }

  void _selectPlace(OsmPlace place) {
    widget.onPlaceSelected(place);
    _focusNode.unfocus();
  }
  
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    if (!mounted) return;
    _removeOverlay(); 

    if (_suggestions.isNotEmpty && _focusNode.hasFocus) {
      final renderBox = context.findRenderObject() as RenderBox;
      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero);

      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: offset.dx,
          top: offset.dy + size.height + 6,
          width: size.width,
          child: Material(
            elevation: 4.0,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              // **FIX**: Styling the suggestion box
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: inputBorderColor),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: inputBorderColor),
                itemBuilder: (context, index) {
                  final place = _suggestions[index];
                  return ListTile(
                    title: Text(
                      place.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: darkTextColor, fontSize: 14),
                    ),
                    dense: true,
                    hoverColor: primaryBlue.withOpacity(0.05),
                    onTap: () => _selectPlace(place),
                  );
                },
              ),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: _focusNode,
      controller: widget.controller,
      decoration: widget.decoration ??
          const InputDecoration(
            labelText: 'Search address...',
            border: OutlineInputBorder(),
          ),
      validator: widget.validator,
      onChanged: _onInputChanged,
      cursorColor: Colors.grey.shade700,
      style: const TextStyle(
        color: darkTextColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}