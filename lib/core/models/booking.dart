// lib/core/models/booking.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, accepted }

extension BookingStatusX on BookingStatus {
  String get value => toString().split('.').last; // "pending" / "accepted"
  static BookingStatus from(String s) =>
      s == 'accepted' ? BookingStatus.accepted : BookingStatus.pending;
}

class Booking {
  // Champs demandés
  final String listingid;      // id de l’annonce
  final String homeownerid;    // propriétaire (host)
  final String studentid;      // locataire (student)
  final DateTime start;        // UTC recommandé
  final DateTime end;          // UTC recommandé
  final int nights;            // end - start (en jours)
  final BookingStatus status;  // pending | accepted
  final double price;          // listing.price_per_month / 30 * nights

  const Booking({
    required this.listingid,
    required this.homeownerid,
    required this.studentid,
    required this.start,
    required this.end,
    required this.nights,
    required this.status,
    required this.price,
  });

  /// Fabrique un Booking en calculant `nights` et `price` depuis `pricePerMonth`.
  factory Booking.create({
    required String listingid,
    required String homeownerid,
    required String studentid,
    required DateTime start,
    required DateTime end,
    required double pricePerMonth,
    BookingStatus status = BookingStatus.pending,
    bool roundPriceToCentimes = true,
  }) {
    final n = _computeNights(start, end);
    double p = (pricePerMonth / 30.0) * n;
    if (roundPriceToCentimes) {
      p = double.parse(p.toStringAsFixed(2));
    }
    return Booking(
      listingid: listingid,
      homeownerid: homeownerid,
      studentid: studentid,
      start: start.toUtc(),
      end: end.toUtc(),
      nights: n,
      status: status,
      price: p,
    );
  }

  // --- Helpers ---

  static int _computeNights(DateTime start, DateTime end) {
    final s = DateTime.utc(start.year, start.month, start.day);
    final e = DateTime.utc(end.year, end.month, end.day);
    final d = e.difference(s).inDays;
    return d < 0 ? 0 : d; // 1–5 → 4 nuits (classique)
  }

  Booking copyWith({
    String? listingid,
    String? homeownerid,
    String? studentid,
    DateTime? start,
    DateTime? end,
    int? nights,
    BookingStatus? status,
    double? price,
  }) {
    return Booking(
      listingid: listingid ?? this.listingid,
      homeownerid: homeownerid ?? this.homeownerid,
      studentid: studentid ?? this.studentid,
      start: (start ?? this.start).toUtc(),
      end: (end ?? this.end).toUtc(),
      nights: nights ?? this.nights,
      status: status ?? this.status,
      price: price ?? this.price,
    );
  }

  // --- Firestore (optionnel mais pratique) ---

  Map<String, dynamic> toJson() => {
        'listingid': listingid,
        'homeownerid': homeownerid,
        'studentid': studentid,
        'start': Timestamp.fromDate(start.toUtc()),
        'end': Timestamp.fromDate(end.toUtc()),
        'nights': nights,
        'status': status.value,
        'price': price,
      };

  factory Booking.fromJson(Map<String, dynamic> json) {
    DateTime _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate().toUtc();
      if (v is String) return DateTime.parse(v).toUtc();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
      throw ArgumentError('Invalid date value: $v');
    }

    return Booking(
      listingid: (json['listingid'] ?? '').toString(),
      homeownerid: (json['homeownerid'] ?? '').toString(),
      studentid: (json['studentid'] ?? '').toString(),
      start: _toDate(json['start']),
      end: _toDate(json['end']),
      nights: (json['nights'] as num).toInt(),
      status: BookingStatusX.from((json['status'] ?? 'pending').toString()),
      price: (json['price'] as num).toDouble(),
    );
  }
}
