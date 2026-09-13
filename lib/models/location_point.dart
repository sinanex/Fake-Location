import 'dart:math';

/// Domain model representing a Geographic Location Point
class LocationPoint {
  final double latitude;
  final double longitude;
  final String? name;
  final DateTime? timestamp;
  final double accuracy;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    this.name,
    this.timestamp,
    this.accuracy = 1.0,
  });

  /// Default initial coordinate (e.g. Kochi, Kerala)
  static const LocationPoint defaultPoint = LocationPoint(
    latitude: 9.9312,
    longitude: 76.2673,
    name: 'Kochi, Kerala',
  );

  /// Validates latitude range (-90..90)
  static bool isValidLatitude(double lat) {
    return !lat.isNaN && lat >= -90.0 && lat <= 90.0;
  }

  /// Validates longitude range (-180..180)
  static bool isValidLongitude(double lng) {
    return !lng.isNaN && lng >= -180.0 && lng <= 180.0;
  }

  /// Returns true if both coordinates are within valid bounds
  bool get isValid => isValidLatitude(latitude) && isValidLongitude(longitude);

  LocationPoint copyWith({
    double? latitude,
    double? longitude,
    String? name,
    DateTime? timestamp,
    double? accuracy,
  }) {
    return LocationPoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      name: name ?? this.name,
      timestamp: timestamp ?? this.timestamp,
      accuracy: accuracy ?? this.accuracy,
    );
  }

  /// Calculate distance in kilometers to another location point using Haversine formula
  double distanceTo(LocationPoint other) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        cos((other.latitude - latitude) * p) / 2 +
        cos(latitude * p) *
            cos(other.latitude * p) *
            (1 - cos((other.longitude - longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Linear interpolation between this point and target point at fraction t (0.0 .. 1.0)
  LocationPoint interpolateTo(LocationPoint target, double t) {
    final clampedT = t.clamp(0.0, 1.0);
    final interpolatedLat = latitude + (target.latitude - latitude) * clampedT;
    final interpolatedLng = longitude + (target.longitude - longitude) * clampedT;
    return LocationPoint(
      latitude: interpolatedLat,
      longitude: interpolatedLng,
      name: name != null && target.name != null ? '$name → ${target.name}' : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'name': name,
        'timestamp': timestamp?.toIso8601String(),
        'accuracy': accuracy,
      };

  factory LocationPoint.fromJson(Map<String, dynamic> json) => LocationPoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        name: json['name'] as String?,
        timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  String toString() =>
      'LocationPoint(lat: ${latitude.toStringAsFixed(5)}, lng: ${longitude.toStringAsFixed(5)}${name != null ? ', name: $name' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationPoint &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}
