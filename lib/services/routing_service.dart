import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_point.dart';

/// Result of a road routing request via OSRM
class RoutingResult {
  final List<LocationPoint> waypoints;
  final double distanceKm;
  final double durationMinutes;

  const RoutingResult({
    required this.waypoints,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

/// Service that fetches real road routes using the OSRM public API.
/// No API key required — uses the public demo server.
class RoutingService {
  static const String _osrmBase = 'https://router.project-osrm.org';

  /// Fetch a road route from [start] to [destination].
  /// Returns null if request fails or network is unavailable.
  Future<RoutingResult?> getRoadRoute({
    required LocationPoint start,
    required LocationPoint destination,
  }) async {
    final url = Uri.parse(
      '$_osrmBase/route/v1/driving/'
      '${start.longitude},${start.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson&steps=false',
    );

    try {
      final response = await http
          .get(url, headers: {'User-Agent': 'MockLocationApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final code = json['code'] as String?;
      if (code != 'Ok') return null;

      final routes = json['routes'] as List<dynamic>;
      if (routes.isEmpty) return null;

      final route = routes.first as Map<String, dynamic>;
      final distanceM = (route['distance'] as num).toDouble();
      final durationS = (route['duration'] as num).toDouble();

      // Decode GeoJSON LineString coordinates
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coords = geometry['coordinates'] as List<dynamic>;

      final rawPoints = coords.map((c) {
        final pair = c as List<dynamic>;
        return LocationPoint(
          latitude: (pair[1] as num).toDouble(),
          longitude: (pair[0] as num).toDouble(),
        );
      }).toList();

      return RoutingResult(
        waypoints: rawPoints,
        distanceKm: distanceM / 1000.0,
        durationMinutes: durationS / 60.0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Densify route waypoints so location updates fire at the correct speed interval.
  /// At [speedKmh] with [intervalSec] update period, each step = distance/step km apart.
  static List<LocationPoint> densifyForSpeed({
    required List<LocationPoint> roadPoints,
    required double speedKmh,
    required int intervalSec,
  }) {
    if (roadPoints.length < 2) return roadPoints;

    final stepDistKm = (speedKmh / 3600.0) * intervalSec;
    if (stepDistKm <= 0) return roadPoints;

    final List<LocationPoint> dense = [roadPoints.first];
    double accumulated = 0.0;

    for (int i = 0; i < roadPoints.length - 1; i++) {
      final a = roadPoints[i];
      final b = roadPoints[i + 1];
      final segDist = a.distanceTo(b);

      double walked = 0.0;
      while (walked + stepDistKm - accumulated <= segDist) {
        walked += stepDistKm - accumulated;
        accumulated = 0.0;
        final frac = walked / segDist;
        dense.add(a.interpolateTo(b, frac.clamp(0.0, 1.0)));
      }
      accumulated += segDist - walked;
    }

    if (dense.last != roadPoints.last) {
      dense.add(roadPoints.last);
    }

    return dense;
  }
}
