package com.example.mock_location_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.mock_location/location"
    private lateinit var mockLocationManager: MockLocationManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        mockLocationManager = MockLocationManager(context)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startMockLocation" -> handleStartMockLocation(call, result)
                "updateLocation" -> handleUpdateLocation(call, result)
                "stopMockLocation" -> handleStopMockLocation(result)
                "isMockLocationEnabled" -> handleIsMockLocationEnabled(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handleStartMockLocation(call: MethodCall, result: MethodChannel.Result) {
        val lat = call.argument<Double>("latitude")
        val lng = call.argument<Double>("longitude")

        if (lat == null || lng == null || lat < -90.0 || lat > 90.0 || lng < -180.0 || lng > 180.0) {
            result.error("INVALID_COORDINATES", "Latitude (-90..90) or Longitude (-180..180) is invalid.", null)
            return
        }

        try {
            mockLocationManager.startMockLocation(lat, lng)
            result.success(true)
        } catch (e: SecurityException) {
            result.error("MOCK_LOCATION_NOT_ENABLED", e.message, null)
        } catch (e: Exception) {
            result.error("MOCK_PROVIDER_ERROR", "Failed to start mock location: ${e.localizedMessage}", null)
        }
    }

    private fun handleUpdateLocation(call: MethodCall, result: MethodChannel.Result) {
        val lat = call.argument<Double>("latitude")
        val lng = call.argument<Double>("longitude")
        val speed = call.argument<Double>("speed") ?: 0.0
        val bearing = call.argument<Double>("bearing")?.toFloat() ?: 0.0f

        if (lat == null || lng == null || lat < -90.0 || lat > 90.0 || lng < -180.0 || lng > 180.0) {
            result.error("INVALID_COORDINATES", "Latitude (-90..90) or Longitude (-180..180) is invalid.", null)
            return
        }

        try {
            mockLocationManager.updateLocation(lat, lng, speed, bearing)
            result.success(true)
        } catch (e: SecurityException) {
            result.error("MOCK_LOCATION_NOT_ENABLED", e.message, null)
        } catch (e: Exception) {
            result.error("MOCK_PROVIDER_ERROR", "Failed to update mock location: ${e.localizedMessage}", null)
        }
    }

    private fun handleStopMockLocation(result: MethodChannel.Result) {
        try {
            mockLocationManager.stopMockLocation()
            result.success(true)
        } catch (e: Exception) {
            result.error("MOCK_PROVIDER_ERROR", "Failed to stop mock location: ${e.localizedMessage}", null)
        }
    }

    private fun handleIsMockLocationEnabled(result: MethodChannel.Result) {
        result.success(mockLocationManager.isMockingActive())
    }

    override fun onDestroy() {
        if (::mockLocationManager.isInitialized) {
            mockLocationManager.stopMockLocation()
        }
        super.onDestroy()
    }
}
