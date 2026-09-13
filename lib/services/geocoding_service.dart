import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_point.dart';

class GeocodingSearchResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String? type;

  const GeocodingSearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.type,
  });

  LocationPoint toLocationPoint() {
    return LocationPoint(
      latitude: latitude,
      longitude: longitude,
      name: displayName,
    );
  }
}

/// Service handling place search and reverse geocoding via OpenStreetMap Nominatim API
class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Searches for matching locations given a query string (e.g., "Kochi", "Bangalore")
  Future<List<GeocodingSearchResult>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];

    final Uri uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': query,
      'format': 'json',
      'limit': '5',
      'addressdetails': '1',
    });

    try {
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'MockLocationFlutterApp/1.0 (educational.project@example.com)',
          'Accept-Language': 'en',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          final lat = double.parse(item['lat'].toString());
          final lon = double.parse(item['lon'].toString());
          final name = item['display_name'] as String? ?? 'Unknown Location';
          final type = item['type'] as String?;

          return GeocodingSearchResult(
            displayName: name,
            latitude: lat,
            longitude: lon,
            type: type,
          );
        }).toList();
      } else {
        throw Exception('Geocoding server error: ${response.statusCode}');
      }
    } catch (e) {
      // Return empty list or throw readable error
      return [];
    }
  }
}
