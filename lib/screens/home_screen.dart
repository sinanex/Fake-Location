import 'package:flutter/material.dart';
import '../models/location_point.dart';
import '../services/mock_location_service.dart';
import '../widgets/coordinate_input.dart';
import '../widgets/location_map.dart';
import '../widgets/mock_control_buttons.dart';
import '../widgets/status_card.dart';
import 'route_simulation_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final MockLocationService _mockService = MockLocationService();

  LocationPoint _selectedLocation = LocationPoint.defaultPoint;
  bool _isMocking = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialMockStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkInitialMockStatus();
    }
  }

  Future<void> _checkInitialMockStatus() async {
    final status = await _mockService.isMockLocationEnabled();
    if (mounted) {
      setState(() => _isMocking = status);
    }
  }

  Future<void> _startMockLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _mockService.startMockLocation(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );

      if (mounted) {
        setState(() {
          _isMocking = success;
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '📍 Mock location active at (${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)})',
              ),
              backgroundColor: Colors.green.shade800,
            ),
          );
        }
      }
    } on MockLocationException catch (e) {
      if (mounted) {
        setState(() {
          _isMocking = false;
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMocking = false;
          _isLoading = false;
          _errorMessage = 'Failed to start mock location: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _updateMockLocation(LocationPoint newLocation) async {
    setState(() {
      _selectedLocation = newLocation;
    });

    if (_isMocking) {
      try {
        await _mockService.updateLocation(newLocation.latitude, newLocation.longitude);
      } on MockLocationException catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.message;
          });
        }
      }
    }
  }

  Future<void> _stopMockLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _mockService.stopMockLocation();
      if (mounted) {
        setState(() {
          _isMocking = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mock location stopped.'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } on MockLocationException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to stop mock location: ${e.toString()}';
        });
      }
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _openRouteSimulation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RouteSimulationScreen(initialStartPoint: _selectedLocation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mock Location',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Developer Options Guide',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Map Section
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: LocationMap(
                  currentLocation: _selectedLocation,
                  isMockActive: _isMocking,
                  onLocationSelected: (location) {
                    _updateMockLocation(location);
                  },
                ),
              ),
            ),

            // Controls & Cards Section
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    // Status Indicator Card
                    StatusCard(
                      isMocking: _isMocking,
                      currentLocation: _selectedLocation,
                      errorMessage: _errorMessage,
                      onDismissError: () => setState(() => _errorMessage = null),
                      onHelpTap: _openSettings,
                    ),
                    const SizedBox(height: 12),

                    // Coordinate Input Form
                    CoordinateInput(
                      initialLocation: _selectedLocation,
                      onLocationSet: (location) {
                        _updateMockLocation(location);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Action Control Buttons
                    MockControlButtons(
                      isMocking: _isMocking,
                      isLoading: _isLoading,
                      onStartMock: _startMockLocation,
                      onStopMock: _stopMockLocation,
                      onOpenRouteSimulation: _openRouteSimulation,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
