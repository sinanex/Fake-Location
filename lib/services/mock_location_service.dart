import 'package:flutter/services.dart';
import '../models/location_point.dart';

/// Error codes returned by Android Kotlin native layer
abstract class MockLocationErrorCode {
  static const String mockLocationNotEnabled = 'MOCK_LOCATION_NOT_ENABLED';
  static const String locationPermissionDenied = 'LOCATION_PERMISSION_DENIED';
  static const String invalidCoordinates = 'INVALID_COORDINATES';
  static const String mockProviderError = 'MOCK_PROVIDER_ERROR';
}

/// Custom Exception thrown when mock location operation fails
class MockLocationException implements Exception {
  final String code;
  final String message;
  final dynamic details;

  const MockLocationException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'MockLocationException($code): $message';
}

/// Service class encapsulating MethodChannel communication with native Kotlin LocationManager
class MockLocationService {
  static const MethodChannel _channel = MethodChannel('com.example.mock_location/location');

  /// Starts the mock location provider in Kotlin with initial coordinates
  Future<bool> startMockLocation(double latitude, double longitude) async {
    if (!LocationPoint.isValidLatitude(latitude) || !LocationPoint.isValidLongitude(longitude)) {
      throw const MockLocationException(
        code: MockLocationErrorCode.invalidCoordinates,
        message: 'Latitude must be between -90 and 90, Longitude between -180 and 180.',
      );
    }

    try {
      final bool? success = await _channel.invokeMethod<bool>('startMockLocation', {
        'latitude': latitude,
        'longitude': longitude,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    } catch (e) {
      throw MockLocationException(
        code: MockLocationErrorCode.mockProviderError,
        message: 'Unexpected error starting mock location: ${e.toString()}',
      );
    }
  }

  /// Updates current mock location while mock provider is active
  Future<bool> updateLocation(
    double latitude,
    double longitude, {
    double speed = 0.0,
    double bearing = 0.0,
  }) async {
    if (!LocationPoint.isValidLatitude(latitude) || !LocationPoint.isValidLongitude(longitude)) {
      throw const MockLocationException(
        code: MockLocationErrorCode.invalidCoordinates,
        message: 'Latitude (-90..90) or Longitude (-180..180) is outside valid range.',
      );
    }

    try {
      final bool? success = await _channel.invokeMethod<bool>('updateLocation', {
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'bearing': bearing,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    } catch (e) {
      throw MockLocationException(
        code: MockLocationErrorCode.mockProviderError,
        message: 'Unexpected error updating location: ${e.toString()}',
      );
    }
  }

  /// Stops mock location provider in Android Kotlin
  Future<bool> stopMockLocation() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('stopMockLocation');
      return success ?? false;
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    } catch (e) {
      throw MockLocationException(
        code: MockLocationErrorCode.mockProviderError,
        message: 'Unexpected error stopping mock location: ${e.toString()}',
      );
    }
  }

  /// Checks if mock provider is actively mocking in Kotlin
  Future<bool> isMockLocationEnabled() async {
    try {
      final bool? status = await _channel.invokeMethod<bool>('isMockLocationEnabled');
      return status ?? false;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Helper to convert PlatformException to strongly typed MockLocationException
  MockLocationException _mapPlatformException(PlatformException e) {
    return MockLocationException(
      code: e.code,
      message: e.message ?? 'An unknown error occurred in native Android mock service.',
      details: e.details,
    );
  }
}
