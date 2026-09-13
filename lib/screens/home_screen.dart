import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart' show AppColors;
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

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final MockLocationService _mockService = MockLocationService();

  LocationPoint _selectedLocation = LocationPoint.defaultPoint;
  bool _isMocking = false;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _borderController;
  late Animation<double> _borderAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialMockStatus();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _borderAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _borderController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkInitialMockStatus();
  }

  Future<void> _checkInitialMockStatus() async {
    final status = await _mockService.isMockLocationEnabled();
    if (mounted) setState(() => _isMocking = status);
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
            'Location spoofed · ${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}',
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
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _updateMockLocation(LocationPoint newLocation) async {
    setState(() => _selectedLocation = newLocation);
    if (_isMocking) {
      try {
        await _mockService.updateLocation(
          newLocation.latitude,
          newLocation.longitude,
        );
      } on MockLocationException catch (e) {
        if (mounted) setState(() => _errorMessage = e.message);
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
        _showToast('Mock location stopped', isSuccess: false);
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
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _showToast(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isSuccess ? AppColors.success : AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Full-screen Map (fills everything behind sheet) ──────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _borderAnim,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    border: _isMocking
                        ? Border.all(
                            color: AppColors.primary.withValues(
                              alpha: 0.3 + 0.4 * _borderAnim.value,
                            ),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: child,
                );
              },
              child: GestureDetector(
                // Tapping map collapses sheet to 20 %
                onTap: () {
                  _sheetController.animateTo(
                    0.20,
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                  );
                },
                child: LocationMap(
                  currentLocation: _selectedLocation,
                  isMockActive: _isMocking,
                  onLocationSelected: (loc) {
                    _updateMockLocation(loc);
                    // Expand sheet slightly so user sees the update
                    _sheetController.animateTo(
                      0.45,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ),
            ),
          ),

          // ── Floating Top Bar ─────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _GlassBadge(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShaderMask(
                            shaderCallback: (r) => const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                            ).createShader(r),
                            child: const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'MockLoc',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _StatusPill(isActive: _isMocking),
                    const SizedBox(width: 10),
                    _GlassIconButton(
                      icon: Icons.tune_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Draggable Bottom Sheet ────────────────────────────────────────
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.45,
            minChildSize: 0.20,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.20, 0.45, 0.88],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 24,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 6),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Scrollable content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                        children: [
                          StatusCard(
                            isMocking: _isMocking,
                            currentLocation: _selectedLocation,
                            errorMessage: _errorMessage,
                            onDismissError: () =>
                                setState(() => _errorMessage = null),
                            onHelpTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          CoordinateInput(
                            initialLocation: _selectedLocation,
                            onLocationSet: _updateMockLocation,
                          ),
                          const SizedBox(height: 12),
                          MockControlButtons(
                            isMocking: _isMocking,
                            isLoading: _isLoading,
                            onStartMock: _startMockLocation,
                            onStopMock: _stopMockLocation,
                            onOpenRouteSimulation: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RouteSimulationScreen(
                                  initialStartPoint: _selectedLocation,
                                ),
                              ),
                            ),
                          ),
                          // Bottom safe-area padding
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Shared Glass Widgets ─────────────────────────────────────────────────────

class _GlassBadge extends StatelessWidget {
  final Widget child;
  const _GlassBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

class _StatusPill extends StatefulWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isActive
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: widget.isActive
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isActive)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Opacity(
                opacity: _pulse.value,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(width: 7),
          Text(
            widget.isActive ? 'Live' : 'Idle',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.isActive
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
