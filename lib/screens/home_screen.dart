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
          _showToast(
            '📍 Location spoofed at (${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)})',
            isSuccess: true,
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
        _showToast('Mock location stopped.', isSuccess: false);
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

  void _showToast(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.info_rounded,
              color: isSuccess ? Colors.greenAccent : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Map (top, full-bleed with safe area) ──
          Expanded(
            flex: 11,
            child: Stack(
              children: [
                Positioned.fill(
                  child: LocationMap(
                    currentLocation: _selectedLocation,
                    isMockActive: _isMocking,
                    onLocationSelected: _updateMockLocation,
                  ),
                ),
                // Top bar overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          // App logo badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, size: 18, color: Color(0xFF111111)),
                                SizedBox(width: 6),
                                Text(
                                  'MockLoc',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111111),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Status pill
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isMocking ? const Color(0xFF111111) : Colors.white,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _PulsingDot(active: _isMocking),
                                const SizedBox(width: 6),
                                Text(
                                  _isMocking ? 'Live' : 'Idle',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isMocking ? Colors.white : const Color(0xFF111111),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Settings
                          GestureDetector(
                            onTap: _openSettings,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.10),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.more_horiz_rounded, size: 20, color: Color(0xFF111111)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Panel (white card sheet) ──
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status row
                        StatusCard(
                          isMocking: _isMocking,
                          currentLocation: _selectedLocation,
                          errorMessage: _errorMessage,
                          onDismissError: () => setState(() => _errorMessage = null),
                          onHelpTap: _openSettings,
                        ),
                        const SizedBox(height: 16),

                        // Coordinate Input
                        CoordinateInput(
                          initialLocation: _selectedLocation,
                          onLocationSet: _updateMockLocation,
                        ),
                        const SizedBox(height: 16),

                        // Action Buttons
                        MockControlButtons(
                          isMocking: _isMocking,
                          isLoading: _isLoading,
                          onStartMock: _startMockLocation,
                          onStopMock: _stopMockLocation,
                          onOpenRouteSimulation: _openRouteSimulation,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pulsing status dot
class _PulsingDot extends StatefulWidget {
  final bool active;
  const _PulsingDot({required this.active});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFBBBBBB),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF22C55E),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
