// lib/core/services/booking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart'; // <-- adapte le chemin si besoin

class BookingService {
  BookingService._();
  static final BookingService _instance = BookingService._();
  factory BookingService() => _instance;

  final _db = FirebaseFirestore.instance;

  /// Crée une réservation PENDING pour un listing.
  /// - Calcule nights et price = pricePerMonth/30 * nights
  /// - Vérifie l’inclusion dans une fenêtre de disponibilité (si le listing en a)
  /// - Optionnel: refuse si chevauche une réservation ACCEPTED existante (par défaut: true)
  Future<String> createPendingBooking({
    required String listingId,
    required String studentId,
    required DateTime start,
    required DateTime end,
    bool blockIfOverlapsAccepted = true,
  }) async {
    // Normalise en UTC (dates "nuitée": end = checkout exclusif)
    final sUtc = DateTime.utc(start.year, start.month, start.day);
    final eUtc = DateTime.utc(end.year, end.month, end.day);
    if (!eUtc.isAfter(sUtc)) {
      throw ArgumentError('End must be after Start.');
    }

    // Récup listing: ownerId, pricePerMonth, windows
    final listing = await _fetchListingSnapshot(listingId);

    // Inclusion dans une fenêtre de dispo (si configurée)
    if (listing.windows.isNotEmpty &&
        !_isWithinAnyWindow(sUtc, eUtc, listing.windows)) {
      throw StateError('Dates hors des fenêtres de disponibilité du listing.');
    }

    // Bloquer si chevauche une accepted existante (sécurité côté création)
    if (blockIfOverlapsAccepted) {
      final overlap = await hasAcceptedOverlap(
        listingId: listingId,
        start: sUtc,
        end: eUtc,
      );
      if (overlap) {
        throw StateError(
          'Chevauchement avec une réservation déjà acceptée.',
        );
      }
    }

    // Créer le Booking (pending)
    final booking = Booking.create(
      listingid: listingId,
      homeownerid: listing.ownerId,
      studentid: studentId,
      start: sUtc,
      end: eUtc,
      pricePerMonth: listing.pricePerMonth,
      status: BookingStatus.pending,
    );

    final ref = await _db.collection('bookings').add(booking.toJson());
    return ref.id;
  }

  /// Accepte une réservation si aucune autre réservation ACCEPTED ne chevauche.
  /// Met à jour `status = accepted`.
  Future<void> acceptBooking(String bookingId) async {
    final bookingRef = _db.collection('bookings').doc(bookingId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(bookingRef);
      if (!snap.exists) {
        throw StateError('Booking introuvable.');
      }
      // ✅ Cast propre
      final data = Map<String, dynamic>.from(snap.data() as Map);

      final listingId = (data['listingid'] ?? '').toString();
      final start = _toUtcDate(data['start']);
      final end = _toUtcDate(data['end']);
      final status = (data['status'] ?? 'pending').toString();

      if (status == 'accepted') {
        // déjà accepté, rien à faire
        return;
      }

      // Vérifie chevauchements ACCEPTED (hors ce booking)
      final overlapQuery = await _db
          .collection('bookings')
          .where('listingid', isEqualTo: listingId)
          .where('status', isEqualTo: 'accepted')
          // Firestore: une seule inégalité possible -> on filtre sur start côté serveur,
          // et on re-filtre localement sur end (voir plus bas).
          .where('start', isLessThan: end)
          .get();

      final anyOverlap = overlapQuery.docs.any((d) {
        if (d.id == bookingId) return false;
        final m = Map<String, dynamic>.from(d.data() as Map);
        final otherEnd = _toUtcDate(m['end']);
        // Overlap si other.end > start (on a déjà start < end via la requête)
        return otherEnd.isAfter(start);
      });

      if (anyOverlap) {
        throw StateError(
          'Conflit: une réservation acceptée chevauche déjà ces dates.',
        );
      }

      tx.update(bookingRef, {'status': 'accepted'});
    });
  }

  /// Refuse une réservation = suppression du document.
  Future<void> refuseBooking(String bookingId) async {
    await _db.collection('bookings').doc(bookingId).delete();
  }

  /// Supprime un booking (utilitaire)
  Future<void> deleteBooking(String bookingId) => refuseBooking(bookingId);

  /// Liste bookings d’un propriétaire (option: status)
  Future<List<Booking>> listForHomeowner({
    required String homeownerId,
    String? status, // 'pending' | 'accepted'
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collection('bookings')
        .where('homeownerid', isEqualTo: homeownerId)
        .orderBy('start');
    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }
    final qs = await q.limit(limit).get();
    return qs.docs
        .map((d) =>
            Booking.fromJson(Map<String, dynamic>.from(d.data() as Map)))
        .toList();
  }

  /// Liste bookings d’un étudiant (option: status)
  Future<List<Booking>> listForStudent({
    required String studentId,
    String? status,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collection('bookings')
        .where('studentid', isEqualTo: studentId)
        .orderBy('start');
    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }
    final qs = await q.limit(limit).get();
    return qs.docs
        .map((d) =>
            Booking.fromJson(Map<String, dynamic>.from(d.data() as Map)))
        .toList();
  }

  /// Liste bookings pour une annonce (option: status)
  Future<List<Booking>> listForListing({
    required String listingId,
    String? status,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> q = _db
        .collection('bookings')
        .where('listingid', isEqualTo: listingId)
        .orderBy('start');
    if (status != null) {
      q = q.where('status', isEqualTo: status);
    }
    final qs = await q.limit(limit).get();
    return qs.docs
        .map((d) =>
            Booking.fromJson(Map<String, dynamic>.from(d.data() as Map)))
        .toList();
  }

  /// Chevauchement avec une réservation ACCEPTED.
  /// Firestore ne permet qu’UNE inégalité par requête :
  /// - On filtre serveur sur: start < endDemande
  /// - Puis on re-filtre côté client sur: other.end > startDemande
  Future<bool> hasAcceptedOverlap({
    required String listingId,
    required DateTime start,
    required DateTime end,
    String? excludeBookingId,
  }) async {
    final q = await _db
        .collection('bookings')
        .where('listingid', isEqualTo: listingId)
        .where('status', isEqualTo: 'accepted')
        .where('start', isLessThan: end)
        .get();

    for (final d in q.docs) {
      if (excludeBookingId != null && d.id == excludeBookingId) continue;
      // ✅ Cast propre
      final m = Map<String, dynamic>.from(d.data() as Map);
      final otherEnd = _toUtcDate(m['end']);
      if (otherEnd.isAfter(start)) {
        return true;
      }
    }
    return false;
  }

  // ----------------- Helpers internes -----------------

  DateTime _toUtcDate(dynamic v) {
    if (v is Timestamp) return v.toDate().toUtc();
    if (v is String) return DateTime.parse(v).toUtc();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
    throw ArgumentError('Invalid date value: $v');
    // NOTE: les modèles et l’UI doivent envoyer des dates normalisées (UTC, jour entier).
  }

  bool _isWithinAnyWindow(
    DateTime start,
    DateTime end,
    List<_Window> windows,
  ) {
    for (final w in windows) {
      // Inclusion stricte dans une fenêtre
      if (!start.isBefore(w.start) && !end.isAfter(w.end)) {
        return true;
      }
    }
    return false;
  }

  Future<_ListingSnapshot> _fetchListingSnapshot(String listingId) async {
    final snap = await _db.collection('Listing').doc(listingId).get();
    if (!snap.exists) {
      throw StateError('Listing introuvable.');
    }
    // ✅ Cast propre
    final data = Map<String, dynamic>.from(snap.data() as Map);

    // ownerId (homeowner)
    final ownerId = (data['ownerId'] ?? data['homeownerid'] ?? '').toString();

    // pricePerMonth (on accepte camelCase ou snake_case)
    double ppm = 0.0;
    final v1 = data['rentPerMonth'];
    final v2 = data['price_per_month'];
    if (v1 is num) {
      ppm = v1.toDouble();
    } else if (v2 is num) {
      ppm = v2.toDouble();
    } else if (v1 is String) {
      ppm = double.tryParse(v1) ?? 0.0;
    } else if (v2 is String) {
      ppm = double.tryParse(v2) ?? 0.0;
    }

    // availability.windows: [{start: ts, end: ts}, ...]
    final windows = <_Window>[];
    final avail = data['availability'];
    if (avail is Map && avail['windows'] is List) {
      final av = Map<String, dynamic>.from(avail as Map);
      for (final x in (av['windows'] as List)) {
        if (x is Map) {
          final m = Map<String, dynamic>.from(x);
          final s = _toUtcDate(m['start']);
          final e = _toUtcDate(m['end']);
          windows.add(_Window(s, e));
        }
      }
    }

    return _ListingSnapshot(
      ownerId: ownerId,
      pricePerMonth: ppm,
      windows: windows,
    );
  }
}

// ----- Snapshots internes -----
class _ListingSnapshot {
  final String ownerId;
  final double pricePerMonth;
  final List<_Window> windows;
  _ListingSnapshot({
    required this.ownerId,
    required this.pricePerMonth,
    required this.windows,
  });
}

class _Window {
  final DateTime start;
  final DateTime end;
  _Window(this.start, this.end);
}
