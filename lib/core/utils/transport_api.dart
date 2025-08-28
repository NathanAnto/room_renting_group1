import 'dart:convert';
import 'package:http/http.dart' as http;

/// Récupère toutes les connexions disponibles sur les 2 prochaines heures
/// entre deux points géographiques (lat/lon).
Future<Map<String, dynamic>> getItinerariesNext2hByCoords({
  required double fromLat,
  required double fromLon,
  required double toLat,
  required double toLon,
  int pageLimitSafety = 20, // garde-fou pour éviter une boucle infinie
  int pageSize = 6, // nombre de connexions renvoyées par page (typique de l’API)
}) async {
  // -- Helpers ---------------------------------------------------------------
  Future<String> _resolveToQueryParam(double lat, double lon) async {
    final uri = Uri.https(
      'transport.opendata.ch',
      '/v1/locations',
      {
        'x': lat.toString(), // latitude
        'y': lon.toString(), // longitude
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Locations lookup failed (${res.statusCode}): ${res.body}');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final stations = (data['stations'] as List?) ?? [];
    if (stations.isEmpty) {
      throw Exception('Aucune station trouvée pour $lat,$lon');
    }

    final first = stations.first as Map<String, dynamic>;
    final id = (first['id'] as String?)?.trim();
    if (id != null && id.isNotEmpty) return id;

    final name = (first['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;

    throw Exception('Résolution de station invalide pour $lat,$lon');
  }

  DateTime? _extractDeparture(Map<String, dynamic> connection) {
    // Format API: connection['from']['departure'] est un ISO-8601
    try {
      final from = connection['from'] as Map<String, dynamic>?;
      final dep = from?['departure'] as String?;
      if (dep == null) return null;
      return DateTime.parse(dep);
    } catch (_) {
      return null;
    }
  }

  // -- Résolution des extrémités --------------------------------------------
  final fromParam = await _resolveToQueryParam(fromLat, fromLon);
  final toParam   = await _resolveToQueryParam(toLat, toLon);

  // Fenêtre temporelle: maintenant → +2h (en heure locale de l’app)
  final now = DateTime.now();
  final windowEnd = now.add(const Duration(hours: 2));

  // Requête paginée /v1/connections
  final collected = <Map<String, dynamic>>[];
  int page = 0;
  bool reachedEnd = false;

  while (!reachedEnd && page < pageLimitSafety) {
    final query = <String, String>{
      'from': fromParam,
      'to': toParam,
      'limit': pageSize.toString(),
      // Date et heure au moment de la requête initiale
      'date': now.toIso8601String().substring(0, 10),
      'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'page': page.toString(), // page 0 = maintenant, 1 = plus tard, etc.
    };

    final uri = Uri.https('transport.opendata.ch', '/v1/connections', query);
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Connections lookup failed (${res.statusCode}): ${res.body}');
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    final conns = (body['connections'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    if (conns.isEmpty) {
      // Plus de résultats côté API
      break;
    }

    // Filtrer celles dans la fenêtre [now, windowEnd]
    for (final c in conns) {
      final dep = _extractDeparture(c);
      if (dep == null) continue;
      if (dep.isBefore(now)) continue; // avant fenêtre
      if (dep.isAfter(windowEnd)) {
        // On vient de dépasser la fenêtre -> on peut arrêter après cette page
        reachedEnd = true;
        continue;
      }
      collected.add(c);
    }

    // Si la dernière connexion de la page dépasse la fenêtre, on arrête.
    final lastDep = _extractDeparture(conns.last);
    if (lastDep != null && lastDep.isAfter(windowEnd)) {
      reachedEnd = true;
    }

    page += 1;
  }

  return {
    'from': fromParam,
    'to': toParam,
    'window': {
      'start': now.toIso8601String(),
      'end': windowEnd.toIso8601String(),
    },
    'count': collected.length,
    'connections': collected,
  };
}
