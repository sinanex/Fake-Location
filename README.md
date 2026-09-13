# Mock Location - Flutter + Native Android Kotlin Application

An educational and testing Flutter application built with native Android Kotlin integration to demonstrate how **Android Mock Location** works using official `LocationManager` test provider APIs via Flutter `MethodChannel`.

---

## 📱 Features

- **Interactive Map**: OpenStreetMap integration via `flutter_map` with tap-to-select coordinates and real-time marker positioning.
- **Location Search**: Integrated geocoding (Nominatim API) to search places like *Kochi, Calicut, Bangalore, Delhi, London*.
- **Coordinate Validation**: Precise range validation for decimal Latitude (`-90..90`) and Longitude (`-180..180`).
- **MethodChannel Service**: Dedicated Dart service layer managing native platform calls to Android Kotlin.
- **Native Kotlin Mock Service**: Configures Android `LocationManager.GPS_PROVIDER` test provider, setting latitude, longitude, altitude, accuracy, speed, bearing, and system realtime nanoseconds.
- **Route Simulation**: Advanced route generator that calculates waypoints between Start and Destination points, simulating movement at configurable speeds (10–120 km/h) with real-time map progress.
- **Developer Options Guidance**: Built-in step-by-step diagnostic guide for setting up Mock Location on Android test devices.

---

## 🏗️ Architecture

```text
Flutter UI (HomeScreen / RouteSimulationScreen)
       │
       ▼
Flutter Service Layer (MockLocationService)
       │
       ▼  [ MethodChannel: com.example.mock_location/location ]
       │
Native Android Kotlin (MainActivity.kt)
       │
       ▼
MockLocationManager.kt
       │
       ▼
Android LocationManager / Test Provider APIs
       │
       ▼
Android System Location Framework
```

---

## 📂 Project Structure

```text
mock_location_app/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── kotlin/com/example/mock_location_app/
│           ├── MainActivity.kt          # MethodChannel handler
│           └── MockLocationManager.kt   # Android LocationManager test provider logic
├── lib/
│   ├── main.dart                        # Flutter app entrypoint & Material 3 theme
│   ├── models/
│   │   ├── location_point.dart          # Coordinate model & distance/interpolation math
│   │   └── route_point.dart             # Route simulation state & step calculation
│   ├── services/
│   │   ├── mock_location_service.dart   # MethodChannel Dart abstraction
│   │   ├── map_service.dart             # Map tile server config & marker styling
│   │   ├── geocoding_service.dart       # Nominatim place search service
│   │   └── route_simulation_service.dart# Timer-driven route simulation controller
│   ├── widgets/
│   │   ├── location_map.dart            # Interactive FlutterMap widget
│   │   ├── coordinate_input.dart        # Latitude/Longitude input form & presets
│   │   ├── mock_control_buttons.dart    # Start/Stop Mock action buttons
│   │   └── status_card.dart             # Real-time mock status card
│   └── screens/
│       ├── home_screen.dart             # Main home screen
│       ├── route_simulation_screen.dart # Route simulation & animation screen
│       └── settings_screen.dart         # Developer Options guide & diagnostics
└── pubspec.yaml
```

---

## 🛠️ MethodChannel API Reference

Channel Name: `com.example.mock_location/location`

| Method | Arguments | Returns | Description |
|---|---|---|---|
| `startMockLocation` | `latitude`, `longitude` | `bool` | Initializes test provider & injects initial location |
| `updateLocation` | `latitude`, `longitude`, `speed`, `bearing` | `bool` | Updates injected location on test provider |
| `stopMockLocation` | None | `bool` | Disables and removes test provider cleanly |
| `isMockLocationEnabled` | None | `bool` | Returns true if test provider is currently mocking |

### Error Codes

- `MOCK_LOCATION_NOT_ENABLED`: Thrown when "Select mock location app" is not configured in Android Developer Options.
- `INVALID_COORDINATES`: Thrown when latitude or longitude is outside valid bounds.
- `MOCK_PROVIDER_ERROR`: Thrown when `LocationManager` fails to add or update the test provider.

---

## ⚙️ Android Setup & Developer Options Guide

To allow this app to inject mock location on an Android device or emulator:

1. Open **Android Settings**.
2. Go to **About Phone** → Tap **Build Number** 7 times to enable Developer Options.
3. Go to **Settings → System → Developer Options**.
4. Scroll down to **Select mock location app** (or *Allow mock locations*).
5. Select **mock_location_app**.

---

## 🚀 How to Run

Ensure you have Flutter SDK installed.

```bash
# Get dependencies
flutter pub get

# Run on connected Android device/emulator
flutter run
```

---

## ⚠️ Important Educational Note & System Restrictions

This application uses standard, supported Android development APIs (`LocationManager.addTestProvider` / `setTestProviderLocation`).

- It requires explicit user approval in Android **Developer Options**.
- It does **not** bypass Android security, root devices, or alter system partitions.
- It is intended strictly for development, testing, and educational purposes.
