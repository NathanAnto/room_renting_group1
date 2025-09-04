import 'dart:convert';
import 'package:http/http.dart' as http;

class Place {
  final String name;
  final String address;
  final double? distanceMeters; // si ton API la fournit

  Place({
    required this.name,
    required this.address,
    this.distanceMeters,
  });

  @override
  String toString() => '$name — $address';
}

Future<List<Place>> fetchNearbyPlaces(double lat, double lon) async {
  const apiKey = "30082fbbcfb0451281fb8c64c875b577";
  final url = Uri.parse(
    "https://api.geoapify.com/v2/places?categories=catering.cafe,commercial.supermarket&filter=circle:$lon,$lat,750&limit=10&apiKey=$apiKey",
  );

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final features = data["features"] as List;

      return features.map((f) {
        final props = f["properties"];
        return Place(
          name: props["name"],
          address: props["address_line2"],
          distanceMeters: props["distance"]?.toDouble(),
        );
      }).toList();
    } else {
      print("Erreur: ${response.statusCode} - ${response.body}");
      return [];
    }
  } catch (e) {
    print("Erreur de requête: $e");
    return [];
  }
}

