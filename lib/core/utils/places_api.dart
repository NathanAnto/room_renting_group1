import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> fetchNearbyCafes(double lat, double lon) async {
  const apiKey = "30082fbbcfb0451281fb8c64c875b577";
  final url = Uri.parse(
    "https://api.geoapify.com/v2/places?categories=catering.cafe,commercial.supermarket&filter=circle:$lon,$lat,500&limit=10&apiKey=$apiKey",
  );

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final features = data["features"] as List;

      for (var f in features) {
        final props = f["properties"];
        print("Nom: ${props["name"]}, Adresse: ${props["address_line2"]}");
      }
    } else {
      print("Erreur: ${response.statusCode} - ${response.body}");
    }
  } catch (e) {
    print("Erreur de requête: $e");
  }
}

void main() {
  fetchNearbyCafes(46.227192, 7.363315);
}