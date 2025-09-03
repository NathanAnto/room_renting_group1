// lib/features/bookings/widgets/booking_planner_button.dart
import 'package:flutter/material.dart' as m;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/listing.dart';
import '../../../core/models/booking.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/profile_service.dart';

class BookingPlannerButton extends m.StatefulWidget {
  final Listing listing;

  const BookingPlannerButton({super.key, required this.listing});

  @override
  m.State<BookingPlannerButton> createState() => _BookingPlannerButtonState();
}

class _BookingPlannerButtonState extends m.State<BookingPlannerButton> {
  bool _busy = false;
  bool _bookingsLoaded = false;
  List<Booking> _acceptedBookings = [];

  @override
  void initState() {
    super.initState();
    _loadAcceptedBookings(); // précharge, mais on ré-attend juste avant le picker
  }

  @override
  m.Widget build(m.BuildContext context) {
    return m.FutureBuilder<bool>(
      future: _currentUserIsStudent(),
      builder: (context, snap) {
        if (snap.connectionState == m.ConnectionState.waiting) {
          return const m.SizedBox.shrink();
        }
        final isStudent = snap.data == true;
        if (!isStudent) return const m.SizedBox.shrink();

        return m.Padding(
          padding: const m.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: m.SizedBox(
            width: double.infinity,
            child: m.ElevatedButton.icon(
              icon: _busy
                  ? const m.SizedBox(
                      width: 16, height: 16, child: m.CircularProgressIndicator(strokeWidth: 2))
                  : const m.Icon(m.Icons.event_available_outlined),
              label: const m.Text('Planifier un booking'),
              onPressed: _busy ? null : _openPlanner,
            ),
          ),
        );
      },
    );
  }

  Future<bool> _currentUserIsStudent() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final profile = await ProfileService().getUserProfile(uid);
    return profile?.role == UserRole.student;
  }

  Future<void> _loadAcceptedBookings() async {
    final id = widget.listing.id;
    if (id == null || id.isEmpty) return;
    try {
      final bookings = await BookingService().listForListing(
        listingId: id,
        status: 'accepted', // on récupère seulement les ACCEPTED
      );
      setState(() {
        _acceptedBookings = bookings;
        _bookingsLoaded = true;
      });
    } catch (_) {
      setState(() {
        _acceptedBookings = [];
        _bookingsLoaded = true;
      });
    }
  }

  Future<void> _openPlanner() async {
    final listing = widget.listing;
    final user = FirebaseAuth.instance.currentUser;

    if (listing.id == null || listing.id!.isEmpty) {
      _toast('Listing sans identifiant.');
      return;
    }
    if (user == null) {
      _toast('Connecte-toi pour réserver.');
      return;
    }

    // ✅ On s’assure que les bookings acceptés sont chargés avant d’ouvrir le picker.
    if (!_bookingsLoaded) {
      await _loadAcceptedBookings();
    }

    final now = DateTime.now();
    final start = _findFirstSelectableDate();
    final end = start.add(const Duration(days: 7));

    final m.DateTimeRange? picked = await m.showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 3, 12, 31),
      initialDateRange: m.DateTimeRange(start: start, end: end),
      helpText: 'Sélectionne la période',
      saveText: 'Continuer',
      // ✅ ASTUCE QUI RÈGLE TON PROBLÈME DE TYPES :
      // on ne met AUCUNE annotation de type sur les paramètres.
      // Dart infère (DateTime, DateTimeRange?) du contexte → pas de clash.
      selectableDayPredicate: (day, start, end) => _isSelectableDay(day),
    );

    if (picked == null) return;

    // Double sécurité : on revalide la plage choisie (au cas où).
    final invalid = _firstInvalidDayInRange(picked);
    if (invalid != null) {
      _toast('Période invalide : le ${_fmt(invalid)} n’est pas disponible.');
      return;
    }

    setState(() => _busy = true);
    try {
      await BookingService().createPendingBooking(
        listingId: listing.id!,
        studentId: user.uid,
        start: picked.start,
        end: picked.end,
        blockIfOverlapsAccepted: true, // empêche aussi côté service
      );
      if (!mounted) return;
      _toast('Demande de réservation envoyée (pending).');
    } catch (e) {
      if (!mounted) return;
      _toast('Impossible de créer la réservation: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------- Sélection / validation ----------

  DateTime _findFirstSelectableDate() {
    final now = DateTime.now();
    DateTime d = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < 180; i++) {
      if (_isSelectableDay(d)) return d;
      d = d.add(const Duration(days: 1));
    }
    return DateTime(now.year, now.month, now.day);
  }

  /// Retourne le 1er jour invalide de [range], sinon null.
  DateTime? _firstInvalidDayInRange(m.DateTimeRange range) {
    for (DateTime d = DateTime(range.start.year, range.start.month, range.start.day);
        d.isBefore(range.end);
        d = d.add(const Duration(days: 1))) {
      if (!_isSelectableDay(d)) return d;
    }
    return null;
  }

  /// Règles : (1) dans une fenêtre de dispo si définie, (2) pas dans un booking ACCEPTED
  bool _isSelectableDay(DateTime dayLocal) {
    if (!_isAllowedByAvailability(dayLocal, widget.listing)) return false;
    if (_isInsideAcceptedBooking(dayLocal)) return false;
    return true;
  }

  bool _isAllowedByAvailability(DateTime dayLocal, Listing listing) {
    final windows = listing.availability?.windows ?? const [];
    if (windows.isEmpty) return true;

    // Comparaison en UTC, normalisée minuit
    final dUtc = DateTime.utc(dayLocal.year, dayLocal.month, dayLocal.day);
    for (final w in windows) {
      final ws = DateTime.utc(w.start.year, w.start.month, w.start.day);
      final we = DateTime.utc(w.end.year, w.end.month, w.end.day);
      final inWindow = !dUtc.isBefore(ws) && !dUtc.isAfter(we);
      if (inWindow) return true;
    }
    return false;
  }

  /// end exclusif (checkout) : autorise le jour == end
  bool _isInsideAcceptedBooking(DateTime dayLocal) {
    final dUtc = DateTime.utc(dayLocal.year, dayLocal.month, dayLocal.day);
    for (final b in _acceptedBookings) {
      final s = DateTime.utc(b.start.year, b.start.month, b.start.day);
      final e = DateTime.utc(b.end.year, b.end.month, b.end.day);
      if (!dUtc.isBefore(s) && dUtc.isBefore(e)) return true; // s <= d < e
    }
    return false;
  }

  // ---------- UI helpers ----------

  void _toast(String msg) {
    m.ScaffoldMessenger.of(context).showSnackBar(m.SnackBar(content: m.Text(msg)));
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
