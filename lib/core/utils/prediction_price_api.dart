import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fonction pour obtenir le prix prédit
Future<double?> fetchPredictedPrice({
  required double surfaceM2,
  required int numRooms,
  required String type,
  required bool isFurnished,
  required bool wifiIncl,
  required bool chargesIncl,
  required bool carPark,
  required double distPublicTransportKm,
  required double proximHessoKm,
}) async {
  final url = Uri.parse("https://price-prediction-model-sx7h.onrender.com/predict");

  final body = {
    "surface_m2": surfaceM2,
    "num_rooms": numRooms,
    "type": type,
    "is_furnished": isFurnished,
    "wifi_incl": wifiIncl,
    "charges_incl": chargesIncl,
    "car_park": carPark,
    "dist_public_transport_km": distPublicTransportKm,
    "proxim_hesso_km": proximHessoKm,
  };

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data["predicted_price"] as num).toDouble();
    } else {
      print("Erreur serveur: ${response.statusCode} - ${response.body}");
      return null;
    }
  } catch (e) {
    print("Erreur de requête: $e");
    return null;
  }
}
