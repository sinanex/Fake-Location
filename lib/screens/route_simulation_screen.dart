import 'package:flutter/material.dart';
import '../models/location_point.dart';
import '../models/route_point.dart';
import '../services/route_simulation_service.dart';
import '../widgets/location_map.dart';

class RouteSimulationScreen extends StatefulWidget {
  final LocationPoint initialStartPoint;

  const RouteSimulationScreen({
    super.key,
    required this.initialStartPoint,
  });

  @override
  State<RouteSimulationScreen> createState() => _RouteSimulationScreenState();
}

class _RouteSimulationScreenState extends State<RouteSimulationScreen> {
  final RouteSimulationService _simulationService = RouteSimulationService();

  late LocationPoint _startPoint;
  late LocationPoint _destinationPoint;
  double _speedKmh = 30.0;
  final int _intervalSeconds = 1;

  RouteSimulationState? _simulationState;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startPoint = widget.initialStartPoint;
    // Default destination: ~5km away from start point
    _destinationPoint = LocationPoint(
      latitude: _startPoint.latitude + 0.03,
      longitude: _startPoint.longitude + 0.03,
      name: 'Destination Point',
    );
    _recalculateRoute();
  }

  @override
  void dispose() {
    _simulationService.dispose();
    super.dispose();
  }

  void _recalculateRoute() {
    final state = RouteSimulationState.initial(
      start: _startPoint,
      destination: _destinationPoint,
      speedKmh: _speedKmh,
      updateIntervalSeconds: _intervalSeconds,
    );
    setState(() {
      _simulationState = state;
    });
  }

  void _startSimulation() {
    if (_simulationState == null) return;
    setState(() => _errorMessage = null);

    _simulationService.startSimulation(
      initialState: _simulationState!,
      onStateChanged: (updatedState) {
        if (mounted) {
          setState(() => _simulationState = updatedState);
        }
      },
      onError: (errorMsg) {
        if (mounted) {
          setState(() => _errorMessage = errorMsg);
        }
      },
      onCompleted: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Route Simulation completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  void _stopSimulation() {
    _simulationService.stopSimulation();
    if (mounted && _simulationState != null) {
      setState(() {
        _simulationState = _simulationState!.copyWith(isRunning: false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRunning = _simulationState?.isRunning ?? false;
    final currentLoc = _simulationState?.currentLocation ?? _startPoint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Simulation'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Map section
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: LocationMap(
                currentLocation: currentLoc,
                isMockActive: isRunning,
                routeWaypoints: _simulationState?.waypoints,
                currentRouteIndex: _simulationState?.currentIndex,
                onLocationSelected: (selectedPt) {
                  if (!isRunning) {
                    setState(() {
                      _destinationPoint = selectedPt.copyWith(name: 'Selected Destination');
                    });
                    _recalculateRoute();
                  }
                },
              ),
            ),
          ),

          // Control & configuration sheet
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  // Route Progress Bar
                  if (_simulationState != null) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Simulation Progress',
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${(_simulationState!.progress * 100).toStringAsFixed(1)}%',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _simulationState!.progress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.indigo,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Step: ${_simulationState!.currentIndex + 1} / ${_simulationState!.waypoints.length}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Distance: ${_simulationState!.totalDistanceKm.toStringAsFixed(2)} km',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Speed & Interval sliders
                  Text(
                    'Speed Configuration: ${_speedKmh.toInt()} km/h',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _speedKmh,
                    min: 10.0,
                    max: 120.0,
                    divisions: 22,
                    label: '${_speedKmh.toInt()} km/h',
                    onChanged: isRunning
                        ? null
                        : (val) {
                            setState(() => _speedKmh = val);
                            _recalculateRoute();
                          },
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          shape:
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Start Coordinates',
                                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(
                                  '${_startPoint.latitude.toStringAsFixed(4)}, ${_startPoint.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.grey),
                      Expanded(
                        child: Card(
                          shape:
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Destination (Tap map)',
                                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(
                                  '${_destinationPoint.latitude.toStringAsFixed(4)}, ${_destinationPoint.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Start/Stop Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isRunning ? null : _startSimulation,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Simulation'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: !isRunning ? null : _stopSimulation,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
