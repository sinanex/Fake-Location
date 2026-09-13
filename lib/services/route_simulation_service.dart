import 'dart:async';
import 'dart:math';
import '../models/location_point.dart';
import '../models/route_point.dart';
import 'mock_location_service.dart';

class RouteSimulationService {
  final MockLocationService _mockLocationService;
  Timer? _timer;
  RouteSimulationState? _state;

  RouteSimulationService({MockLocationService? mockLocationService})
      : _mockLocationService = mockLocationService ?? MockLocationService();

  RouteSimulationState? get state => _state;
  bool get isRunning => _timer != null && _timer!.isActive;

  /// Starts or resumes route simulation
  void startSimulation({
    required RouteSimulationState initialState,
    required Function(RouteSimulationState updatedState) onStateChanged,
    required Function(String error) onError,
    required Function() onCompleted,
  }) async {
    stopSimulation(); // Cancel existing timer if running

    _state = initialState.copyWith(isRunning: true, currentIndex: 0);
    onStateChanged(_state!);

    // Initialize mock location with start point
    try {
      await _mockLocationService.startMockLocation(
        _state!.startPoint.latitude,
        _state!.startPoint.longitude,
      );
    } catch (err) {
      final errorMsg = err is MockLocationException ? err.message : err.toString();
      onError(errorMsg);
      stopSimulation();
      return;
    }

    final intervalMs = (_state!.updateIntervalSeconds * 1000).toInt();

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) async {
      if (_state == null || !_state!.isRunning) {
        timer.cancel();
        return;
      }

      final nextIndex = _state!.currentIndex + 1;

      if (nextIndex >= _state!.waypoints.length) {
        // Reached destination
        stopSimulation();
        onCompleted();
        return;
      }

      final currentPt = _state!.waypoints[nextIndex];

      // Calculate bearing to next point for natural direction orientation
      double bearing = 0.0;
      if (nextIndex < _state!.waypoints.length - 1) {
        final nextPt = _state!.waypoints[nextIndex + 1];
        bearing = _calculateBearing(currentPt, nextPt);
      }

      try {
        await _mockLocationService.updateLocation(
          currentPt.latitude,
          currentPt.longitude,
          speed: _state!.speedKmh,
          bearing: bearing,
        );

        _state = _state!.copyWith(currentIndex: nextIndex);
        onStateChanged(_state!);
      } catch (err) {
        final errorMsg = err is MockLocationException ? err.message : err.toString();
        onError(errorMsg);
        stopSimulation();
      }
    });
  }

  /// Pauses or stops route simulation and cleans up timer
  void stopSimulation() {
    _timer?.cancel();
    _timer = null;
    if (_state != null) {
      _state = _state!.copyWith(isRunning: false);
    }
  }

  /// Calculates bearing in degrees (0..360) between two coordinates
  double _calculateBearing(LocationPoint p1, LocationPoint p2) {
    const double degreesToRadians = 0.017453292519943295;
    const double radiansToDegrees = 57.29577951308232;

    final lat1 = p1.latitude * degreesToRadians;
    final lat2 = p2.latitude * degreesToRadians;
    final dLng = (p2.longitude - p1.longitude) * degreesToRadians;

    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    final bearing = (atan2(y, x) * radiansToDegrees + 360) % 360;

    return bearing;
  }

  void dispose() {
    stopSimulation();
  }
}
