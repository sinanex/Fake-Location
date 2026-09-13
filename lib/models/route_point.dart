import 'location_point.dart';

/// Represents a route simulation with start, destination, interpolated waypoints, speed and interval settings.
class RouteSimulationState {
  final LocationPoint startPoint;
  final LocationPoint destinationPoint;
  final List<LocationPoint> waypoints;
  final double speedKmh;
  final int updateIntervalSeconds;
  final int currentIndex;
  final bool isRunning;

  const RouteSimulationState({
    required this.startPoint,
    required this.destinationPoint,
    required this.waypoints,
    this.speedKmh = 30.0,
    this.updateIntervalSeconds = 1,
    this.currentIndex = 0,
    this.isRunning = false,
  });

  /// Factory constructor initializing a new route between two points
  factory RouteSimulationState.initial({
    required LocationPoint start,
    required LocationPoint destination,
    double speedKmh = 30.0,
    int updateIntervalSeconds = 1,
  }) {
    final generatedWaypoints = _generateWaypoints(
      start: start,
      destination: destination,
      speedKmh: speedKmh,
      intervalSec: updateIntervalSeconds,
    );

    return RouteSimulationState(
      startPoint: start,
      destinationPoint: destination,
      waypoints: generatedWaypoints,
      speedKmh: speedKmh,
      updateIntervalSeconds: updateIntervalSeconds,
      currentIndex: 0,
      isRunning: false,
    );
  }

  /// Current location along the route
  LocationPoint get currentLocation {
    if (waypoints.isEmpty) return startPoint;
    if (currentIndex >= waypoints.length) return waypoints.last;
    return waypoints[currentIndex];
  }

  /// Progress fraction (0.0 to 1.0)
  double get progress {
    if (waypoints.isEmpty) return 0.0;
    return (currentIndex / (waypoints.length - 1)).clamp(0.0, 1.0);
  }

  /// Total distance of route in kilometers
  double get totalDistanceKm => startPoint.distanceTo(destinationPoint);

  /// Estimated duration in minutes based on configured speed
  double get estimatedMinutes => speedKmh > 0 ? (totalDistanceKm / speedKmh) * 60 : 0;

  RouteSimulationState copyWith({
    LocationPoint? startPoint,
    LocationPoint? destinationPoint,
    List<LocationPoint>? waypoints,
    double? speedKmh,
    int? updateIntervalSeconds,
    int? currentIndex,
    bool? isRunning,
  }) {
    return RouteSimulationState(
      startPoint: startPoint ?? this.startPoint,
      destinationPoint: destinationPoint ?? this.destinationPoint,
      waypoints: waypoints ?? this.waypoints,
      speedKmh: speedKmh ?? this.speedKmh,
      updateIntervalSeconds: updateIntervalSeconds ?? this.updateIntervalSeconds,
      currentIndex: currentIndex ?? this.currentIndex,
      isRunning: isRunning ?? this.isRunning,
    );
  }

  /// Generates step waypoints given distance, speed, and time interval
  static List<LocationPoint> _generateWaypoints({
    required LocationPoint start,
    required LocationPoint destination,
    required double speedKmh,
    required int intervalSec,
  }) {
    final distanceKm = start.distanceTo(destination);

    // Speed in km/s = speedKmh / 3600
    final distancePerStepKm = (speedKmh / 3600.0) * intervalSec;

    if (distanceKm <= 0 || distancePerStepKm <= 0) {
      return [start, destination];
    }

    final totalSteps = (distanceKm / distancePerStepKm).ceil();
    final clampedSteps = totalSteps.clamp(2, 500); // Minimum 2 steps, cap at 500

    final List<LocationPoint> points = [];
    for (int i = 0; i <= clampedSteps; i++) {
      final double fraction = i / clampedSteps;
      points.add(start.interpolateTo(destination, fraction));
    }
    return points;
  }
}
