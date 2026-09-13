package com.example.mock_location_app

import android.content.Context
import android.location.Criteria
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.SystemClock

class MockLocationManager(private val context: Context) {

    private val locationManager: LocationManager =
        context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

    private var isMocking: Boolean = false
    private val providerName: String = LocationManager.GPS_PROVIDER

    /**
     * Starts mock location service by adding a test provider and enabling it.
     */
    @Throws(SecurityException::class, IllegalArgumentException::class)
    fun startMockLocation(lat: Double, lng: Double) {
        setupTestProvider()
        isMocking = true
        updateLocation(lat, lng)
    }

    /**
     * Registers and enables the test provider in Android LocationManager.
     */
    @Throws(SecurityException::class)
    private fun setupTestProvider() {
        try {
            // Remove existing provider if any to prevent state conflicts
            try {
                locationManager.removeTestProvider(providerName)
            } catch (e: Exception) {
                // Safe to ignore if provider wasn't registered yet
            }

            locationManager.addTestProvider(
                providerName,
                false, // requiresNetwork
                false, // requiresSatellite
                false, // requiresCell
                false, // hasMonetaryCost
                true,  // supportsAltitude
                true,  // supportsSpeed
                true,  // supportsBearing
                Criteria.POWER_LOW, // powerRequirement
                Criteria.ACCURACY_FINE // accuracy
            )

            locationManager.setTestProviderEnabled(providerName, true)
        } catch (e: SecurityException) {
            isMocking = false
            throw SecurityException("Mock location permission denied. Enable mock location app in Developer Options.", e)
        }
    }

    /**
     * Injects a mock location with latitude, longitude, and required Android system timestamps.
     */
    @Throws(SecurityException::class, IllegalStateException::class)
    fun updateLocation(lat: Double, lng: Double, speedKmh: Double = 0.0, bearingDeg: Float = 0.0f) {
        if (!isMocking) {
            setupTestProvider()
            isMocking = true
        }

        try {
            val speedMps = (speedKmh / 3.6).toFloat()

            val mockLocation = Location(providerName).apply {
                latitude = lat
                longitude = lng
                altitude = 0.0
                time = System.currentTimeMillis()
                elapsedRealtimeNanos = SystemClock.elapsedRealtimeNanos()
                accuracy = 1.0f
                speed = speedMps
                bearing = bearingDeg

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    bearingAccuracyDegrees = 0.1f
                    verticalAccuracyMeters = 0.5f
                    speedAccuracyMetersPerSecond = 0.1f
                }
            }

            locationManager.setTestProviderLocation(providerName, mockLocation)
        } catch (e: SecurityException) {
            isMocking = false
            throw SecurityException("Mock location permission lost. Please re-enable in Developer Options.", e)
        } catch (e: Exception) {
            throw IllegalStateException("Failed to update test provider location: ${e.localizedMessage}", e)
        }
    }

    /**
     * Disables and removes the test provider cleanly.
     */
    fun stopMockLocation() {
        if (!isMocking) return
        try {
            locationManager.setTestProviderEnabled(providerName, false)
            locationManager.removeTestProvider(providerName)
        } catch (e: Exception) {
            // Ignore clean shutdown errors
        } finally {
            isMocking = false
        }
    }

    /**
     * Checks if mock location is active.
     */
    fun isMockingActive(): Boolean = isMocking
}
