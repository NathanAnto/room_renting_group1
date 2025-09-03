// lib/features/listings/screens/create_listing_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:room_renting_group1/core/models/listing.dart';
import 'package:room_renting_group1/core/models/ListingAvailability.dart';
import 'package:room_renting_group1/core/services/listing_service.dart';
import 'package:room_renting_group1/core/utils/prediction_price_api.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _svc = ListingService();

  // --- Étape 1 (champs nécessaires à la prédiction) ---
  final _addressCtrl = TextEditingController();
  final _surfaceCtrl = TextEditingController();
  final _roomsCtrl = TextEditingController();

  bool _isFurnished = false;
  bool _wifiIncl = false;
  bool _chargesIncl = false;
  bool _carPark = false;

  // Coordonnées & distances (calculées)
  double? _lat;
  double? _lng;
  double? _distPublicTransportKm;
  double? _distNearestHesKm;

  // Autocomplete Nominatim
  List<_OsmPlace> _suggestions = [];
  Timer? _debounce;
  _OsmPlace? _selectedPlace; // <--- ajouté

  // --- Étape 2 (après prédiction) ---
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rentCtrl = TextEditingController();        // éditable
  final _predictedCtrl = TextEditingController();   // read-only affichage

  // Images
  final List<String> _images = [];

  // Disponibilités
  final List<AvailabilityWindow> _windows = [];
  final List<String> _blackoutDates = [];
  final _minStayCtrl = TextEditingController();
  final _maxStayCtrl = TextEditingController();
  final _timezoneCtrl = TextEditingController(text: 'Europe/Zurich');

  // Statut
  String _status = 'draft';
  static const _statusValues = ['draft', 'active', 'paused', 'archived'];

  // UI state
  bool _predicting = false;
  bool _saving = false;
  bool _hasPrediction = false; // contrôle l’affichage de l’étape 2

  // ---------- Const HES ----------
  static const Map<String, List<double>> kDefaultSchoolCoords = {
    "École de Design et Haute Ecole d'Art (EDHEA)": [46.291300, 7.520950],
    "Haute Ecole de Gestion (HEG)": [46.293050, 7.536450],
    "Haute Ecole d'Ingénierie (HEI)": [46.227420, 7.363820],
    "Haute Ecole de Santé (HES)": [46.235870, 7.351330],
    "Haute Ecole et Ecole Supérieure de Travail Social (HESTS)": [46.293050, 7.536450],
  };

  @override
  void dispose() {
    _addressCtrl.dispose();
    _surfaceCtrl.dispose();
    _roomsCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _rentCtrl.dispose();
    _predictedCtrl.dispose();
    _minStayCtrl.dispose();
    _maxStayCtrl.dispose();
    _timezoneCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ------------------- Helpers -------------------
  String get _typeFromRooms {
    final n = int.tryParse(_roomsCtrl.text) ?? 0;
    return n <= 1 ? 'room' : 'entire_home';
  }

  double _pDouble(String v) => double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
  int _pInt(String v) => int.tryParse(v) ?? 0;

  String _fmt2(double? v) => v == null ? '—' : v.toStringAsFixed(2);

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null;

  String _guessImageContentType(PlatformFile f) {
    final ext = (f.extension ?? '').toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  // Extrait la ville depuis un _OsmPlace (priorité city > town > village)
  String _extractCityFromOsm(_OsmPlace p) {
    final s = (p.city ?? p.town ?? p.village ?? '').trim();
    return s;
  }

  // ------------------- Étape 1 : Nominatim -------------------
  void _onAddressChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (q.trim().length < 3) {
        if (mounted) setState(() => _suggestions = []);
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

  Future<List<_OsmPlace>> _searchNominatim(String q) async {
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
    return data.map((e) => _OsmPlace.fromJson(e)).toList();
  }

  Future<void> _selectPlace(_OsmPlace p) async {
    _selectedPlace = p; // <--- enregistré
    _addressCtrl.text = p.displayName;
    _suggestions = [];
    _lat = p.lat;
    _lng = p.lon;

    await _updateHesDistance();
    await _updatePublicTransportDistance();

    setState(() {});
  }

  // ------------------- Distances auto -------------------
  Future<void> _updateHesDistance() async {
    if (_lat == null || _lng == null) {
      _distNearestHesKm = null;
      return;
    }
    double best = double.infinity;
    for (final entry in kDefaultSchoolCoords.entries) {
      final d = _haversineKm(_lat!, _lng!, entry.value[0], entry.value[1]);
      if (d < best) best = d;
    }
    _distNearestHesKm = best.isFinite ? double.parse(best.toStringAsFixed(3)) : null;
  }

  Future<void> _updatePublicTransportDistance() async {
    if (_lat == null || _lng == null) {
      _distPublicTransportKm = null;
      return;
    }
    try {
      final km = await _fetchNearestStationDistanceKm(_lat!, _lng!);
      _distPublicTransportKm = km != null ? double.parse(km.toStringAsFixed(3)) : null;
    } catch (_) {
      _distPublicTransportKm = null;
    }
  }

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _deg2rad(double d) => d * (math.pi / 180.0);

  Future<double?> _fetchNearestStationDistanceKm(double lat, double lon) async {
    final uri = Uri.https('transport.opendata.ch', '/v1/locations', {
      'x': lon.toString(),
      'y': lat.toString(),
      'type': 'station',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final data = json.decode(utf8.decode(res.bodyBytes));
    List list = [];
    if (data is Map && data['stations'] is List) {
      list = data['stations'] as List;
    } else if (data is Map && data['locations'] is List) {
      list = data['locations'] as List;
    }
    if (list.isEmpty) return null;

    double bestMeters = double.infinity;
    for (final s in list) {
      final m = (s['distance'] is num) ? (s['distance'] as num).toDouble() : double.infinity;
      if (m < bestMeters) bestMeters = m;
    }
    if (!bestMeters.isFinite) return null;
    return bestMeters / 1000.0;
  }

  // ------------------- Prédiction -------------------
  bool _canPredict() {
    final hasCoords = _lat != null && _lng != null;
    final surface = _pDouble(_surfaceCtrl.text);
    final rooms = _pInt(_roomsCtrl.text);
    return hasCoords && surface > 0 && rooms > 0;
  }

  Future<void> _predictPrice() async {
    if (!_canPredict()) return;
    setState(() => _predicting = true);
    try {
      final api = PricePredictionApi();
      final price = await api.predictPrice(
        surfaceM2: _pDouble(_surfaceCtrl.text),
        numRooms: _pInt(_roomsCtrl.text),
        type: _typeFromRooms, // auto: room / entire_home
        isFurnished: _isFurnished,
        wifiIncl: _wifiIncl,
        chargesIncl: _chargesIncl,
        carPark: _carPark,
        distPublicTransportKm: _distPublicTransportKm ?? 0.0,
        proximHessoKm: _distNearestHesKm ?? 0.0,
      ); // double? possible

      if (!mounted) return;

      final p = (price ?? 0).toDouble();
      _predictedCtrl.text = p.toStringAsFixed(0);
      if (_rentCtrl.text.trim().isEmpty) {
        _rentCtrl.text = _predictedCtrl.text;
      }
      _hasPrediction = true;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la prédiction: $e')),
      );
    } finally {
      if (mounted) setState(() => _predicting = false);
    }
  }

  // ------------------- Upload images -------------------
  Future<void> _pickAndUploadImages() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: kIsWeb,
    );
    if (result == null) return;

    for (final f in result.files) {
      try {
        final fileName = f.name;
        final path =
            'listing_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        final ref = FirebaseStorage.instance.ref(path);

        UploadTask task;
        if (kIsWeb) {
          if (f.bytes == null) continue;
          task = ref.putData(
            f.bytes!,
            SettableMetadata(contentType: _guessImageContentType(f)),
          );
        } else {
          if (f.path == null) continue;
          task = ref.putFile(File(f.path!));
        }
        final snap = await task;
        final url = await snap.ref.getDownloadURL();
        setState(() => _images.add(url));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload image échoué: $e')),
        );
      }
    }
  }

  // ------------------- Disponibilités -------------------
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
      _windows.add(AvailabilityWindow(start: start.toUtc(), end: end.toUtc()));
    });
  }

  Future<void> _pickBlackout() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 3, 12, 31),
      helpText: 'Ajouter un blackout',
    );
    if (d == null) return;
    final key =
        "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    if (!_blackoutDates.contains(key)) {
      setState(() => _blackoutDates.add(key));
    }
  }

  // ------------------- Save -------------------
  Future<void> _save() async {
    if (!_hasPrediction) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposez un prix avant d’enregistrer.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    final ownerId = user?.uid ?? '';

    // ville auto depuis _selectedPlace (si renseignée)
    final inferredCity = _selectedPlace == null ? '' : _extractCityFromOsm(_selectedPlace!);

    final listing = Listing(
      id: null,
      ownerId: ownerId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: _typeFromRooms, // auto
      rentPerMonth: _pDouble(_rentCtrl.text),
      predictedRentPerMonth:
          _predictedCtrl.text.trim().isEmpty ? 0 : _pDouble(_predictedCtrl.text),
      city: inferredCity, // <--- rempli automatiquement
      addressLine: _addressCtrl.text.trim(),
      lat: _lat ?? 0,
      lng: _lng ?? 0,
      surface: _pDouble(_surfaceCtrl.text),
      distanceToPublicTransportKm: _distPublicTransportKm ?? 0,
      proximHessoKm: _distNearestHesKm ?? 0,
      numRooms: _pInt(_roomsCtrl.text),
      availability: ListingAvailability(
        windows: _windows,
        blackoutDates: _blackoutDates,
        minStayNights: _minStayCtrl.text.isEmpty ? null : _pInt(_minStayCtrl.text),
        maxStayNights: _maxStayCtrl.text.isEmpty ? null : _pInt(_maxStayCtrl.text),
        timezone: _timezoneCtrl.text.trim().isEmpty
            ? 'Europe/Zurich'
            : _timezoneCtrl.text.trim(),
        monthsIndex: const [],
      ),
      amenities: {
        'is_furnished': _isFurnished,
        'wifi_incl': _wifiIncl,
        'charges_incl': _chargesIncl,
        'car_park': _carPark,
      },
      status: _status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      images: _images,
    );

    setState(() => _saving = true);
    try {
      await _svc.addListing(listing);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing créé avec succès.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ------------------- UI -------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un listing'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Étape 1 · Estimation rapide', [
              _addressField(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _number(
                      _surfaceCtrl,
                      'Surface (m²)',
                      validator: _req,
                      invalidatePredictionOnChange: true,  // <-- invalide
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _number(
                      _roomsCtrl,
                      'Nombre de pièces',
                      validator: _req,
                      invalidatePredictionOnChange: true,  // <-- invalide
                      refreshTypeOnChange: true,           // <-- met à jour le chip type
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text('Type: ${_typeFromRooms == 'room' ? 'room' : 'entire_home'}'),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilterChip(
                    label: const Text('Meublé'),
                    selected: _isFurnished,
                    onSelected: (v) => setState(() => _isFurnished = v),
                  ),
                  FilterChip(
                    label: const Text('WiFi inclus'),
                    selected: _wifiIncl,
                    onSelected: (v) => setState(() => _wifiIncl = v),
                  ),
                  FilterChip(
                    label: const Text('Charges incluses'),
                    selected: _chargesIncl,
                    onSelected: (v) => setState(() => _chargesIncl = v),
                  ),
                  FilterChip(
                    label: const Text('Parking'),
                    selected: _carPark,
                    onSelected: (v) => setState(() => _carPark = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _readonly('Distance TP la plus proche (km)', _fmt2(_distPublicTransportKm)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _readonly('Proximité HES (km)', _fmt2(_distNearestHesKm)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _predicting || !_canPredict() ? null : _predictPrice,
                  icon: _predicting
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: Text(_predicting ? 'Calcul…' : 'Proposer un prix'),
                ),
              ),
              if (_hasPrediction) ...[
                const SizedBox(height: 8),
                Text('Prix suggéré : ${_predictedCtrl.text} CHF',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ]),

            if (_hasPrediction)
              _section('Étape 2 · Détails de l’annonce', [
                _text(_titleCtrl, 'Titre *', validator: _req),
                _multiline(_descCtrl, 'Description *', validator: _req),
                Row(
                  children: [
                    Expanded(child: _number(_rentCtrl, 'Loyer CHF/mois *', validator: _req)),
                    const SizedBox(width: 12),
                    Expanded(child: _number(_predictedCtrl, 'Loyer suggéré CHF/mois', readOnly: true)),
                  ],
                ),
                const SizedBox(height: 8),
                _imagesSection(),
                const SizedBox(height: 8),
                _disposSection(),
                const SizedBox(height: 8),
                _dropdownStatus(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  // ------------------- UI helpers -------------------
  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _text(TextEditingController c, String label,
      {String? helper, String? Function(String?)? validator, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label, helperText: helper, border: const OutlineInputBorder()),
        validator: validator,
        readOnly: readOnly,
      ),
    );
  }

  Widget _multiline(TextEditingController c, String label,
      {String? Function(String?)? validator, int maxLines = 3}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  Widget _number(
    TextEditingController c,
    String label, {
    String? Function(String?)? validator,
    bool readOnly = false,

    // Nouveaux drapeaux
    bool invalidatePredictionOnChange = false,
    bool refreshTypeOnChange = false, // utile pour le chip room/entire_home
  }) {
    return TextFormField(
      controller: c,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ).copyWith(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
      validator: validator,
      readOnly: readOnly,
      onChanged: (_) {
        if (invalidatePredictionOnChange && _hasPrediction) {
          setState(() => _hasPrediction = false);
        }
        if (refreshTypeOnChange) {
          setState(() {}); // pour rafraîchir le chip Type
        }
      },
    );
  }


  Widget _readonly(String label, String value) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      controller: TextEditingController(text: value),
    );
  }

  Widget _dropdownStatus() {
    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Statut', border: OutlineInputBorder()),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _status,
          isExpanded: true,
          onChanged: (v) => setState(() => _status = v ?? 'draft'),
          items: _statusValues
              .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
              .toList(),
        ),
      ),
    );
  }

  Widget _imagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickAndUploadImages,
              icon: const Icon(Icons.upload),
              label: const Text('Ajouter des images'),
            ),
            const SizedBox(width: 12),
            Text('${_images.length} image(s)'),
          ],
        ),
        const SizedBox(height: 8),
        if (_images.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _images
                .asMap()
                .entries
                .map(
                  (e) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          e.value,
                          width: 140,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: InkWell(
                          onTap: () => setState(() => _images.removeAt(e.key)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _disposSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickWindow,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une fenêtre'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_windows.isEmpty)
          const Text('Aucune fenêtre ajoutée pour l’instant.', style: TextStyle(color: Colors.grey)),
        if (_windows.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _windows.map((w) {
              String fmt(DateTime d) =>
                  "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
              return Chip(label: Text("${fmt(w.start)} → ${fmt(w.end)} (fin excl.)"));
            }).toList(),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _number(_minStayCtrl, 'Min nuits')),
            const SizedBox(width: 12),
            Expanded(child: _number(_maxStayCtrl, 'Max nuits')),
            const SizedBox(width: 12),
            Expanded(child: _text(_timezoneCtrl, 'Timezone', helper: 'IANA (ex. Europe/Zurich)')),
          ],
        ),
      ],
    );
  }

  Widget _addressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _addressCtrl,
          decoration: const InputDecoration(
            labelText: 'Adresse *',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.place_outlined),
          ),
          validator: _req,
          onChanged: _onAddressChanged,
        ),
        if (_lat != null && _lng != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Coordonnées: ${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade700),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _suggestions
                  .map(
                    (p) => ListTile(
                      dense: true,
                      title: Text(p.displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(p.city ?? p.town ?? p.village ?? ''),
                      onTap: () => _selectPlace(p),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// ======= Modèle léger pour Nominatim =======
class _OsmPlace {
  final String displayName;
  final double lat;
  final double lon;
  final String? city;
  final String? town;
  final String? village;

  _OsmPlace({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.city,
    this.town,
    this.village,
  });

  factory _OsmPlace.fromJson(Map<String, dynamic> json) {
    final addr = json['address'] as Map<String, dynamic>? ?? {};
    return _OsmPlace(
      displayName: json['display_name']?.toString() ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '') ?? 0,
      lon: double.tryParse(json['lon']?.toString() ?? '') ?? 0,
      city: addr['city']?.toString(),
      town: addr['town']?.toString(),
      village: addr['village']?.toString(),
    );
  }
}
