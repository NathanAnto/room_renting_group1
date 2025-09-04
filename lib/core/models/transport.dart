// lib/models/itineraries_ui.dart
// Structure de données compacte & pratique pour l'UI + un parseur unique
// qui prend le Map<String,dynamic> retourné par ta fonction getItinerariesNext2hByCoords.

import 'dart:math';

/// Données prêtes pour l'UI (liste d'itinéraires résumés + legs détaillés)
class ItinerariesUI {
  final String fromLabel;      // ex: "Rte de Senaire 15, Orsières"
  final String toLabel;        // ex: "Rue des Entrepôts, Sion"
  final DateTime windowStart;
  final DateTime windowEnd;
  final List<ItineraryUI> itineraries;

  ItinerariesUI({
    required this.fromLabel,
    required this.toLabel,
    required this.windowStart,
    required this.windowEnd,
    required this.itineraries,
  });

  bool get isEmpty => itineraries.isEmpty;
}

class ItineraryUI {
  final DateTime departure;        // heure départ global
  final DateTime arrival;          // heure arrivée globale
  final Duration? duration;        // durée totale
  final int transfers;             // nb de correspondances
  final List<String> products;     // ex: ["R","R","R"]
  final List<LegUI> legs;          // détail des tronçons (marche & transports)

  ItineraryUI({
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.transfers,
    required this.products,
    required this.legs,
  });

  int get durationMinutes => duration?.inMinutes ?? 0;
  int get minutesUntilDeparture =>
      departure.difference(DateTime.now()).inMinutes;

  /// Ligne “principale” pour l’accroche (premier leg de type transit)
  String? get primaryLine {
    for (final l in legs) {
      if (l.type == LegType.transit && l.lineLabel != null && l.lineLabel!.isNotEmpty) {
        return l.lineLabel;
      }
    }
    return null;
  }
}

enum LegType { walk, transit }

class LegUI {
  final LegType type;

  // Commun
  final String fromName;          // ex: "Orsières"
  final DateTime? fromTime;
  final String? fromPlatform;

  final String toName;            // ex: "Sembrancher"
  final DateTime? toTime;
  final String? toPlatform;

  // Walk
  final int? walkSeconds;

  // Transit
  final String? lineLabel;        // ex: "R 82" ou "026337"
  final String? direction;        // ex: "Sembrancher"
  final String? operatorName;     // ex: "RA"
  final int? stopCount;           // nb arrêts (indicatif)

  LegUI({
    required this.type,
    required this.fromName,
    required this.fromTime,
    required this.fromPlatform,
    required this.toName,
    required this.toTime,
    required this.toPlatform,
    this.walkSeconds,
    this.lineLabel,
    this.direction,
    this.operatorName,
    this.stopCount,
  });

  bool get isWalk => type == LegType.walk;
  Duration? get walkDuration => walkSeconds == null ? null : Duration(seconds: walkSeconds!);
}

/// ===============================
///  FONCTION DE PARSE (UNE SEULE)
/// ===============================
/// Prend le Map<String,dynamic> (return de ta request) et renvoie ItinerariesUI.
ItinerariesUI parseItinerariesUI(Map<String, dynamic> raw) {
  final fromLabel = (raw['from'] ?? '').toString();
  final toLabel   = (raw['to']   ?? '').toString();

  final window = (raw['window'] as Map?)?.cast<String, dynamic>() ?? const {};
  final windowStart = _parseDateTime(window['start']) ?? DateTime.fromMillisecondsSinceEpoch(0);
  final windowEnd   = _parseDateTime(window['end'])   ?? DateTime.fromMillisecondsSinceEpoch(0);

  final connections = (raw['connections'] as List?) ?? const [];

  final items = <ItineraryUI>[];
  for (final c in connections) {
    if (c is! Map) continue;
    final conn = c.cast<String, dynamic>();

    final from = (conn['from'] as Map?)?.cast<String, dynamic>() ?? const {};
    final to   = (conn['to']   as Map?)?.cast<String, dynamic>() ?? const {};

    final dep = _parseDateTime(from['departure']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final arr = _parseDateTime(to['arrival'])     ?? dep;

    final duration = _parseOpendataDuration(conn['duration']?.toString());
    final transfers = _asInt(conn['transfers']) ?? 0;
    final products  = ((conn['products'] as List?) ?? const []).map((e) => e.toString()).toList();

    final sections = (conn['sections'] as List?) ?? const [];
    final legs = <LegUI>[];

    for (final s in sections) {
      if (s is! Map) continue;
      final sec = s.cast<String, dynamic>();

      final depObj = (sec['departure'] as Map?)?.cast<String, dynamic>() ?? const {};
      final arrObj = (sec['arrival']   as Map?)?.cast<String, dynamic>() ?? const {};

      final depStationName = _endpointName(depObj);
      final arrStationName = _endpointName(arrObj);

      final depTime = _parseDateTime(depObj['departure']);
      final arrTime = _parseDateTime(arrObj['arrival']);

      final depPlatform = _asString(depObj['platform']);
      final arrPlatform = _asString(arrObj['platform']);

      final walk = (sec['walk'] as Map?)?.cast<String, dynamic>();
      final journey = (sec['journey'] as Map?)?.cast<String, dynamic>();

      if (walk != null) {
        final walkSeconds = _asInt(walk['duration']); // peut être null
        legs.add(LegUI(
          type: LegType.walk,
          fromName: depStationName,
          fromTime: depTime,
          fromPlatform: depPlatform,
          toName: arrStationName,
          toTime: arrTime,
          toPlatform: arrPlatform,
          walkSeconds: walkSeconds,
        ));
      } else if (journey != null) {
        final category = _asString(journey['category']) ?? '';
        final number = _asString(journey['number']) ?? '';
        final name = _asString(journey['name']) ?? '';
        final operatorName = _asString(journey['operator']);
        final direction = _asString(journey['to']);

        // Label de ligne:
        //  - Si category & number → "R 82"
        //  - Sinon name
        //  - Sinon category
        //  - Sinon number
        final candidateLabels = <String>[
          [category, number].where((e) => e.isNotEmpty).join(' ').trim(),
          name,
          category,
          number,
        ].where((e) => e.trim().isNotEmpty).toList();
        final lineLabel = candidateLabels.isEmpty ? null : candidateLabels.first;

        // stopCount grossier: taille de passList - 1 (si présent)
        final passList = (journey['passList'] as List?) ?? const [];
        final stopCount = passList.isEmpty ? null : max(0, passList.length - 1);

        legs.add(LegUI(
          type: LegType.transit,
          fromName: depStationName,
          fromTime: depTime,
          fromPlatform: depPlatform,
          toName: arrStationName,
          toTime: arrTime,
          toPlatform: arrPlatform,
          lineLabel: lineLabel,
          direction: direction,
          operatorName: operatorName,
          stopCount: stopCount,
        ));
      } else {
        // Section inconnue → fallback transit sans meta
        legs.add(LegUI(
          type: LegType.transit,
          fromName: depStationName,
          fromTime: depTime,
          fromPlatform: depPlatform,
          toName: arrStationName,
          toTime: arrTime,
          toPlatform: arrPlatform,
        ));
      }
    }

    items.add(ItineraryUI(
      departure: dep,
      arrival: arr,
      duration: duration,
      transfers: transfers,
      products: products,
      legs: legs,
    ));
  }

  return ItinerariesUI(
    fromLabel: fromLabel,
    toLabel: toLabel,
    windowStart: windowStart,
    windowEnd: windowEnd,
    itineraries: items,
  );
}

/// ===============================
/// Helpers parsing robustes
/// ===============================

String _endpointName(Map<String, dynamic> endpoint) {
  // L’API peut mettre le nom sous endpoint.station.name ou endpoint.location.name
  final station = (endpoint['station'] as Map?)?.cast<String, dynamic>();
  final location = (endpoint['location'] as Map?)?.cast<String, dynamic>();
  final fromStation = _asString(station?['name']);
  final fromLocation = _asString(location?['name']);
  return (fromStation ?? fromLocation ?? '').trim();
}

DateTime? _parseDateTime(dynamic v) {
  if (v == null) return null;
  var s = v.toString().trim();
  // Normalise +0200 → +02:00
  final tzNoColon = RegExp(r'([+-]\d{2})(\d{2})$');
  final m = tzNoColon.firstMatch(s);
  if (m != null) {
    s = s.replaceFirst(tzNoColon, '${m.group(1)}:${m.group(2)}');
  }
  try {
    return DateTime.parse(s);
  } catch (_) {
    return null;
  }
}

Duration? _parseOpendataDuration(String? s) {
  if (s == null || s.isEmpty) return null;
  final dPattern = RegExp(r'^(\d+)d(\d{2}):(\d{2}):(\d{2})$');
  final m = dPattern.firstMatch(s);
  if (m != null) {
    final days = int.parse(m.group(1)!);
    final hours = int.parse(m.group(2)!);
    final minutes = int.parse(m.group(3)!);
    final seconds = int.parse(m.group(4)!);
    return Duration(days: days, hours: hours, minutes: minutes, seconds: seconds);
  }
  final hms = RegExp(r'^(\d{2}):(\d{2}):(\d{2})$').firstMatch(s);
  if (hms != null) {
    return Duration(
      hours: int.parse(hms.group(1)!),
      minutes: int.parse(hms.group(2)!),
      seconds: int.parse(hms.group(3)!),
    );
  }
  return null;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
}

String? _asString(dynamic v) => v?.toString();
