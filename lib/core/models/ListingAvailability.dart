import 'package:cloud_firestore/cloud_firestore.dart';

/// Listing availability model (pure Dart, backend-agnostic).
///
/// - Fenêtres sur [start, end) (fin exclusive), dates normalisées à minuit UTC.
/// - monthsIndex: liste de "YYYY-MM" couverts par au moins une fenêtre (utile pour les filtres).
class ListingAvailability {
  final List<AvailabilityWindow> windows;
  /// Jours indisponibles sous forme 'YYYY-MM-DD' (UTC)
  final int? minStayNights;
  final int? maxStayNights;
  final String timezone;           // ex: "Europe/Zurich"
  final List<String> monthsIndex;  // ex: ["2025-09","2025-10"]

  ListingAvailability({
    required this.windows,
    this.minStayNights,
    this.maxStayNights,
    this.timezone = "Europe/Zurich",
    this.monthsIndex = const [],
  });

  /// Badge: disponible aujourd’hui ?
  bool get isAvailableNow {
    final todayUtc = _utcMidnight(DateTime.now().toUtc());
    final todayKey = _dateKey(todayUtc);
    final inAWindow = windows.any((w) => w.containsDateUtc(todayUtc));
    return inAWindow;
  }

  /// "Prochaine dispo" (today si déjà dispo).
  DateTime? get nextAvailableStart {
    final today = _utcMidnight(DateTime.now().toUtc());
    if (isAvailableNow) return today;
    final futureStarts = windows
        .map((w) => w.start)
        .where((s) => !s.isBefore(today))
        .toList()
      ..sort();
    return futureStarts.isEmpty ? null : futureStarts.first;
  }

  ListingAvailability copyWith({
    List<AvailabilityWindow>? windows,
    List<String>? blackoutDates,
    int? minStayNights,
    int? maxStayNights,
    String? timezone,
    List<String>? monthsIndex,
  }) {
    return ListingAvailability(
      windows: windows ?? this.windows,
      minStayNights: minStayNights ?? this.minStayNights,
      maxStayNights: maxStayNights ?? this.maxStayNights,
      timezone: timezone ?? this.timezone,
      monthsIndex: monthsIndex ?? this.monthsIndex,
    );
  }


  factory ListingAvailability.fromMap(Map<String, dynamic> map) {
    return ListingAvailability(
      windows: (map['windows'] as List<dynamic>? ?? [])
          .map((m) => AvailabilityWindow.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      minStayNights: (map['minStayNights'] as num?)?.toInt(),
      maxStayNights: (map['maxStayNights'] as num?)?.toInt(),
      timezone: (map['timezone'] as String?) ?? "Europe/Zurich",
      monthsIndex: (map['monthsIndex'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'windows': windows.map((w) => w.toMap()).toList(),
        'minStayNights': minStayNights,
        'maxStayNights': maxStayNights,
        'timezone': timezone,
        'monthsIndex': monthsIndex,
      };

  /// Recalcule monthsIndex à partir des fenêtres (à appeler avant save).
  ListingAvailability withRefreshedMonthsIndex() {
    final idx = _buildMonthsIndex(windows);
    return ListingAvailability(
      windows: windows,
      minStayNights: minStayNights,
      maxStayNights: maxStayNights,
      timezone: timezone,
      monthsIndex: idx,
    );
  }

  // --- Helpers ---
  static DateTime _utcMidnight(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  static String _dateKey(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  /// Construit un index de mois "YYYY-MM" pour [start, end) (end exclusif).
  static List<String> _buildMonthsIndex(List<AvailabilityWindow> ws) {
    final out = <String>{};
    for (final w in ws) {
      // Premier du mois du début
      var cursor = DateTime.utc(w.start.year, w.start.month, 1);
      // Limite exclusive = 1er jour du mois de end
      final limit = DateTime.utc(w.end.year, w.end.month, 1);
      while (cursor.isBefore(limit)) {
        out.add("${cursor.year.toString().padLeft(4,'0')}-${cursor.month.toString().padLeft(2,'0')}");
        // Mois suivant
        cursor = (cursor.month == 12)
            ? DateTime.utc(cursor.year + 1, 1, 1)
            : DateTime.utc(cursor.year, cursor.month + 1, 1);
      }
    }
    final list = out.toList()..sort();
    return list;
  }

  static String dateToKey(DateTime dUtc) => _dateKey(_utcMidnight(dUtc));
}

/// Fenêtre de disponibilité [start, end) (fin exclusive), normalisée à minuit UTC.
class AvailabilityWindow {
  /// Début inclusif (00:00 UTC)
  final DateTime start;
  /// Fin exclusive (00:00 UTC)
  final DateTime end;
  final String? label;

  /// Constructeur non-const pour autoriser l'assert avec DateTime.
  AvailabilityWindow({
    required DateTime start,
    required DateTime end,
    this.label,
  })  : start = DateTime.utc(start.year, start.month, start.day),
        end = DateTime.utc(end.year, end.month, end.day) {
    assert(
      end.millisecondsSinceEpoch > start.millisecondsSinceEpoch,
      'end must be strictly after start (end is exclusive)',
    );
  }

  /// True si dateUtc ∈ [start, end[
  bool containsDateUtc(DateTime dateUtc) {
    final d = DateTime.utc(dateUtc.year, dateUtc.month, dateUtc.day);
    return (d.isAtSameMomentAs(start) || d.isAfter(start)) && d.isBefore(end);
  }

  /// Fenêtre d'une journée (end = start + 1 jour)
  factory AvailabilityWindow.singleDay(DateTime dayUtc, {String? label}) {
    final d = DateTime.utc(dayUtc.year, dayUtc.month, dayUtc.day);
    return AvailabilityWindow(
      start: d,
      end: d.add(const Duration(days: 1)),
      label: label,
    );
  }

  /// Construit à partir de bornes inclusives "YYYY-MM-DD" (end transformé en exclusif).
  factory AvailabilityWindow.fromInclusiveKeys({
    required String startKey,
    required String endKey,
    String? label,
  }) {
    final s = _parseYmdToUtc(startKey);
    final eIncl = _parseYmdToUtc(endKey);
    final e = eIncl.add(const Duration(days: 1));
    return AvailabilityWindow(start: s, end: e, label: label);
  }

  factory AvailabilityWindow.fromMap(Map<String, dynamic> map) {
    return AvailabilityWindow(
      start: _parseDateUtc(map['start']),
      end: _parseDateUtc(map['end']),
      label: map['label'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        // On stocke en "YYYY-MM-DD" (backend-agnostic)
        'start': _key(start),
        'end': _key(end),
        'label': label,
      };

  static String _key(DateTime d) =>
      "${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}";

  /// Parse divers formats:
  /// - "YYYY-MM-DD" -> minuit UTC
  /// - ISO 8601 avec heure -> normalisé à minuit UTC
  /// - epoch millis (int) -> normalisé à minuit UTC
  static DateTime _parseDateUtc(dynamic v) {
    if (v is String) {
      if (v.length == 10) {
        // "YYYY-MM-DD"
        return _parseYmdToUtc(v);
      }
      // ISO complet
      final dt = DateTime.parse(v).toUtc();
      return DateTime.utc(dt.year, dt.month, dt.day);
    }
    if (v is int) {
      final dt = DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
      return DateTime.utc(dt.year, dt.month, dt.day);
    }
    throw ArgumentError("Unsupported date format for AvailabilityWindow: $v");
  }

  static DateTime _parseYmdToUtc(String ymd) {
    final parts = ymd.split('-'); // [YYYY, MM, DD]
    if (parts.length != 3) {
      throw FormatException('Bad Y-M-D: $ymd');
    }
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    return DateTime.utc(y, m, d);
  }
}
