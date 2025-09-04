import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Simple client for the Student Housing Price API (FastAPI on Render).
class PricePredictionApi {
  /// Change this if you deploy under a different hostname.
  final String baseUrl;

  /// Optional: pass your own http.Client if you want to share it.
  final http.Client _client;

  PricePredictionApi({
    this.baseUrl = "https://price-prediction-model-sx7h.onrender.com",
    http.Client? client,
  }) : _client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse("$baseUrl$path");

  /// Quick health check to "warm up" the Render service (cold starts).
  Future<bool> health() async {
    try {
      final res = await _client
          .get(_uri("/health"))
          .timeout(const Duration(seconds: 20));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Optionally fetch the expected column schema (useful for debugging).
  Future<List<String>?> schema() async {
    try {
      final res = await _client
          .get(_uri("/schema"))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final cols = (data["expected_columns"] as List?)?.cast<String>();
        return cols;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Predict price (CHF) for a single listing.
  ///
  /// The backend expects a JSON payload: {"items": [ { ...one listing... } ] }
  /// and returns: {"predictions": [<double>], "clipped_to_zero": <bool>}
  Future<double?> predictPrice({
    required double surfaceM2,
    required int numRooms,
    required String type, // "room" or "entire_home"
    required bool isFurnished,
    required bool wifiIncl,
    required bool chargesIncl,
    required bool carPark,
    required double distPublicTransportKm,
    required double proximHessoKm,
  }) async {
    final payload = {
      "items": [
        {
          "surface_m2": surfaceM2,
          "num_rooms": numRooms,
          "type": type,
          "is_furnished": isFurnished,
          "wifi_incl": wifiIncl,
          "charges_incl": chargesIncl,
          "car_park": carPark,
          "dist_public_transport_km": distPublicTransportKm,
          "proxim_hesso_km": proximHessoKm,
        }
      ]
    };

    try {
      final res = await _client
          .post(
            _uri("/predict"),
            headers: const {
              HttpHeaders.contentTypeHeader: "application/json",
              HttpHeaders.acceptHeader: "application/json",
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print("Server error ${res.statusCode}: ${res.body}");
        return null;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      // Preferred response shape from the deployed API
      if (data.containsKey("predictions")) {
        final preds = (data["predictions"] as List);
        if (preds.isNotEmpty) return (preds.first as num).toDouble();
      }

      // Fallback: if the API also returns a single field
      if (data.containsKey("predicted_price")) {
        return (data["predicted_price"] as num).toDouble();
      }

      print("Unexpected JSON shape: ${res.body}");
      return null;
    } on SocketException catch (e) {
      print("Network error: $e");
      return null;
    } on FormatException catch (e) {
      print("JSON decode error: $e");
      return null;
    } on HttpException catch (e) {
      print("HTTP exception: $e");
      return null;
    }
  }

  /// Batch predictions if you need to score multiple listings at once.
  Future<List<double>?> predictPricesBatch(List<Map<String, dynamic>> items) async {
    final payload = {"items": items};

    try {
      final res = await _client
          .post(
            _uri("/predict"),
            headers: const {
              HttpHeaders.contentTypeHeader: "application/json",
              HttpHeaders.acceptHeader: "application/json",
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        print("Server error ${res.statusCode}: ${res.body}");
        return null;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final preds = (data["predictions"] as List?) ?? [];
      return preds.map((e) => (e as num).toDouble()).toList();
    } catch (e) {
      print("Batch request error: $e");
      return null;
    }
  }

  void close() => _client.close();
}

/// --- Example usage as a standalone Dart script ---
/// You can delete `main()` in your Flutter app and call `predictPrice()` from your services.
Future<void> main() async {
  final api = PricePredictionApi();

  // Optional warm-up (Render free tier can be cold)
  await api.health();

  final price = await api.predictPrice(
    surfaceM2: 20.0,
    numRooms: 2,
    type: "room",
    isFurnished: false,
    wifiIncl: false,
    chargesIncl: false,
    carPark: false,
    distPublicTransportKm: 1.0,
    proximHessoKm: 10.0,
  );

  if (price != null) {
    print("Predicted price: CHF ${price.toStringAsFixed(2)}");
  } else {
    print("Failed to get predicted price.");
  }

  api.close();
}
