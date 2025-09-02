// lib/features/listings/screens/create_listing_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/models/listing.dart';
import 'package:room_renting_group1/core/models/ListingAvailability.dart';
import '../../../core/services/listing_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _svc = ListingService();

  // --- Text controllers ---
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _typeCtrl = TextEditingController(text: 'apartment');
  final _rentCtrl = TextEditingController();
  final _predictedCtrl = TextEditingController(text: '0');
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _surfaceCtrl = TextEditingController();
  final _distPtCtrl = TextEditingController(); // distanceToPublicTransportKm
  final _proximHessoCtrl = TextEditingController(); // proximHessoKm
  final _roomsCtrl = TextEditingController();

  // images: coma-separated URLs
  final _imagesCtrl = TextEditingController();

  // --- Status (string) ---
  String _status = 'draft';
  static const _statusValues = ['draft', 'active', 'paused', 'archived'];

  // --- Amenities ---
  bool _isFurnished = false;
  bool _wifiIncl = false;
  bool _chargesIncl = false;
  bool _carPark = false;

  // --- Availability model state ---
  final List<AvailabilityWindow> _windows = [];
  final List<String> _blackoutDates = [];
  final _minStayCtrl = TextEditingController();
  final _maxStayCtrl = TextEditingController();
  final _timezoneCtrl = TextEditingController(text: 'Europe/Zurich');

  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _typeCtrl.dispose();
    _rentCtrl.dispose();
    _predictedCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _surfaceCtrl.dispose();
    _distPtCtrl.dispose();
    _proximHessoCtrl.dispose();
    _roomsCtrl.dispose();
    _imagesCtrl.dispose();
    _minStayCtrl.dispose();
    _maxStayCtrl.dispose();
    _timezoneCtrl.dispose();
    super.dispose();
  }

  // --- Helpers parse ---
  double _pDouble(String v) => double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
  int _pInt(String v) => int.tryParse(v) ?? 0;

  Future<void> _pickWindow() async {
    final now = DateTime.now();
    final theme = ShadTheme.of(context);

    final start = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 3, 12, 31),
      helpText: 'Start date (inclusive)',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: theme.colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (start == null) return;

    final end = await showDatePicker(
      context: context,
      initialDate: start.add(const Duration(days: 1)),
      firstDate: start.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 3, 12, 31),
      helpText: 'End date (exclusive)',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: theme.colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (end == null) return;

    setState(() {
      _windows.add(AvailabilityWindow(start: start.toUtc(), end: end.toUtc()));
    });
  }

  Future<void> _pickBlackout() async {
    final now = DateTime.now();
    final theme = ShadTheme.of(context);

    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 3, 12, 31),
      helpText: 'Add a blackout date',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
                  primary: theme.colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (d == null) return;

    final key =
        "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    if (!_blackoutDates.contains(key)) {
      setState(() => _blackoutDates.add(key));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    final ownerId = user?.uid ?? '';

    final listing = Listing(
      id: null,
      ownerId: ownerId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: _typeCtrl.text.trim(),
      rentPerMonth: _pDouble(_rentCtrl.text),
      predictedRentPerMonth: _pDouble(_predictedCtrl.text),
      city: _cityCtrl.text.trim(),
      addressLine: _addressCtrl.text.trim(),
      lat: _pDouble(_latCtrl.text),
      lng: _pDouble(_lngCtrl.text),
      surface: _pDouble(_surfaceCtrl.text),
      distanceToPublicTransportKm: _pDouble(_distPtCtrl.text),
      proximHessoKm: _pDouble(_proximHessoCtrl.text),
      numRooms: _pInt(_roomsCtrl.text),
      availability: ListingAvailability(
        windows: _windows,
        blackoutDates: _blackoutDates,
        minStayNights: _minStayCtrl.text.isEmpty ? null : _pInt(_minStayCtrl.text),
        maxStayNights: _maxStayCtrl.text.isEmpty ? null : _pInt(_maxStayCtrl.text),
        timezone: _timezoneCtrl.text.trim().isEmpty ? 'Europe/Zurich' : _timezoneCtrl.text.trim(),
        monthsIndex: const [], // recalculé côté service
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
      images: _imagesCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );

      setState(() => _saving = true);
      try {
        await _svc.addListing(listing);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing créé avec succès.')),
        );
        Navigator.of(context).pop(); // <-- on ferme sans renvoyer d'id
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un listing'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Informations principales'),
            _row2(
              _fieldText(_titleCtrl, 'Titre *', validator: _req),
              _fieldText(_typeCtrl, 'Type (ex: apartment)', validator: _req),
            ),
            _fieldMulti(_descCtrl, 'Description *', maxLines: 4, validator: _req),
            _row3(
              _fieldNum(_rentCtrl, 'Loyer CHF/mois *', validator: _req),
              _fieldNum(_predictedCtrl, 'Loyer prédit CHF/mois'),
              _dropdownStatus(),
            ),
            _row3(
              _fieldText(_cityCtrl, 'Ville *', validator: _req),
              _fieldText(_addressCtrl, 'Adresse *', validator: _req),
              _fieldText(_imagesCtrl, 'Images (URLs séparées par une virgule)'),
            ),
            const SizedBox(height: 12),
            _sectionTitle('Géolocalisation & surfaces'),
            _row3(
              _fieldNum(_latCtrl, 'Latitude'),
              _fieldNum(_lngCtrl, 'Longitude'),
              _fieldNum(_surfaceCtrl, 'Surface (m²)'),
            ),
            _row2(
              _fieldNum(_distPtCtrl, 'Distance TP (km)'),
              _fieldNum(_proximHessoCtrl, 'Proximité HES-SO (km)'),
            ),
            _fieldNum(_roomsCtrl, 'Nombre de pièces'),

            const SizedBox(height: 12),
            _sectionTitle('Équipements'),
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

            const SizedBox(height: 16),
            _sectionTitle('Disponibilités'),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickWindow,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une fenêtre'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _pickBlackout,
                  icon: const Icon(Icons.event_busy),
                  label: const Text('Ajouter un blackout'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_windows.isEmpty)
              Text('Aucune fenêtre ajoutée pour l’instant.',
                  style: TextStyle(color: theme.colorScheme.mutedForeground)),
            if (_windows.isNotEmpty) _windowsListCard(theme),

            const SizedBox(height: 8),
            if (_blackoutDates.isNotEmpty) _blackoutsListCard(theme),

            const SizedBox(height: 8),
            _row3(
              _fieldNum(_minStayCtrl, 'Min nuits'),
              _fieldNum(_maxStayCtrl, 'Max nuits'),
              _fieldText(_timezoneCtrl, 'Timezone', helper: 'IANA (ex. Europe/Zurich)'),
            ),

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
          ],
        ),
      ),
    );
  }

  // --- Small UI helpers ---
  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null;

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          t,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );

  Widget _row2(Widget a, Widget b) => Row(
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );

  Widget _row3(Widget a, Widget b, Widget c) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
          const SizedBox(width: 12),
          Expanded(child: c),
        ],
      );

  Widget _fieldText(TextEditingController c, String label,
      {String? helper, String? Function(String?)? validator, int maxLines = 1}) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _fieldMulti(TextEditingController c, String label,
      {int maxLines = 3, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _fieldNum(TextEditingController c, String label,
      {String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
      validator: validator,
    );
  }

  Widget _dropdownStatus() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Statut',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _status,
          isExpanded: true,
          onChanged: (v) => setState(() => _status = v ?? 'draft'),
          items: _statusValues
              .map((s) => DropdownMenuItem<String>(
                    value: s,
                    child: Text(s),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _windowsListCard(ShadThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _windows.asMap().entries.map((e) {
            final i = e.key;
            final w = e.value;
            final start = "${w.start.year.toString().padLeft(4, '0')}-${w.start.month.toString().padLeft(2, '0')}-${w.start.day.toString().padLeft(2, '0')}";
            final end = "${w.end.year.toString().padLeft(4, '0')}-${w.end.month.toString().padLeft(2, '0')}-${w.end.day.toString().padLeft(2, '0')}";
            return Chip(
              label: Text("$start → $end (end exclusif)"),
              onDeleted: () {
                setState(() => _windows.removeAt(i));
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _blackoutsListCard(ShadThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _blackoutDates.asMap().entries.map((e) {
            final i = e.key;
            final d = e.value;
            return Chip(
              label: Text("Blackout $d"),
              onDeleted: () {
                setState(() => _blackoutDates.removeAt(i));
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
