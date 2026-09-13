import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../main.dart' show AppColors;
import '../models/location_point.dart';
import '../models/route_point.dart';
import '../services/geocoding_service.dart';

import '../services/route_simulation_service.dart';
import '../services/routing_service.dart';
import '../services/map_service.dart';

// ─── Phases of the screen ────────────────────────────────────────────────────
enum _Phase { pickStart, pickEnd, preview, simulating }

class RouteSimulationScreen extends StatefulWidget {
  final LocationPoint initialStartPoint;
  const RouteSimulationScreen({super.key, required this.initialStartPoint});

  @override
  State<RouteSimulationScreen> createState() => _RouteSimulationScreenState();
}

class _RouteSimulationScreenState extends State<RouteSimulationScreen> {
  final RouteSimulationService _simService = RouteSimulationService();
  final RoutingService _routingService = RoutingService();
  final GeocodingService _geocodingService = GeocodingService();
  final MapController _mapController = MapController();

  late LocationPoint _start;
  LocationPoint? _end;
  List<LocationPoint> _roadWaypoints = [];

  _Phase _phase = _Phase.pickStart;
  double _speedKmh = 40.0;
  bool _isFetchingRoute = false;
  String? _routeError;
  RouteSimulationState? _simState;

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  List<GeocodingSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStartPoint;
    _phase = _Phase.pickEnd; // Start already set, let user pick end
  }

  @override
  void dispose() {
    _simService.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Route fetching ─────────────────────────────────────────────────────────
  Future<void> _fetchRoadRoute() async {
    if (_end == null) return;
    setState(() { _isFetchingRoute = true; _routeError = null; });

    final result = await _routingService.getRoadRoute(start: _start, destination: _end!);

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _isFetchingRoute = false;
        _routeError = 'Could not fetch road route. Using straight-line fallback.';
        // Fallback to straight interpolation
        _roadWaypoints = RouteSimulationState.initial(
          start: _start,
          destination: _end!,
          speedKmh: _speedKmh,
        ).waypoints;
        _phase = _Phase.preview;
      });
    } else {
      final dense = RoutingService.densifyForSpeed(
        roadPoints: result.waypoints,
        speedKmh: _speedKmh,
        intervalSec: 1,
      );
      setState(() {
        _isFetchingRoute = false;
        _roadWaypoints = dense;
        _phase = _Phase.preview;
      });
      // Fit map to route
      try {
        if (_roadWaypoints.length >= 2) {
          final lats = _roadWaypoints.map((p) => p.latitude);
          final lngs = _roadWaypoints.map((p) => p.longitude);
          final bounds = LatLngBounds(
            LatLng(lats.reduce((a, b) => a < b ? a : b),
                lngs.reduce((a, b) => a < b ? a : b)),
            LatLng(lats.reduce((a, b) => a > b ? a : b),
                lngs.reduce((a, b) => a > b ? a : b)),
          );
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
          );
        }
      } catch (_) {}
    }
  }

  // ── Simulation control ─────────────────────────────────────────────────────
  void _startSimulation() {
    if (_roadWaypoints.isEmpty) return;

    final state = RouteSimulationState(
      startPoint: _start,
      destinationPoint: _end!,
      waypoints: _roadWaypoints,
      speedKmh: _speedKmh,
      updateIntervalSeconds: 1,
    );

    setState(() { _phase = _Phase.simulating; _simState = state; });

    _simService.startSimulation(
      initialState: state,
      onStateChanged: (s) { if (mounted) setState(() => _simState = s); },
      onError: (e) { if (mounted) setState(() => _routeError = e); },
      onCompleted: () {
        if (mounted) {
          setState(() => _phase = _Phase.preview);
          _showToast('Route completed! 🎉');
        }
      },
    );
  }

  void _stopSimulation() {
    _simService.stopSimulation();
    setState(() { _phase = _Phase.preview; });
  }

  void _resetRoute() {
    _simService.stopSimulation();
    setState(() {
      _end = null;
      _roadWaypoints = [];
      _simState = null;
      _routeError = null;
      _phase = _Phase.pickEnd;
    });
  }

  // ── Map tap ────────────────────────────────────────────────────────────────
  void _onMapTap(LatLng latLng) {
    if (_phase == _Phase.pickStart) {
      setState(() {
        _start = LocationPoint(latitude: latLng.latitude, longitude: latLng.longitude, name: 'Start');
        _phase = _Phase.pickEnd;
      });
    } else if (_phase == _Phase.pickEnd) {
      setState(() {
        _end = LocationPoint(latitude: latLng.latitude, longitude: latLng.longitude, name: 'Destination');
      });
      _fetchRoadRoute();
    }
  }

  // ── Search ─────────────────────────────────────────────────────────────────
  Future<void> _search(String query) async {
    if (query.trim().length < 2) { setState(() => _searchResults = []); return; }
    setState(() => _isSearching = true);
    final results = await _geocodingService.searchPlaces(query);
    if (mounted) setState(() { _searchResults = results; _isSearching = false; });
  }

  void _selectSearchResult(GeocodingSearchResult r) {
    final pt = r.toLocationPoint();
    _searchCtrl.clear();
    setState(() => _searchResults = []);
    if (_phase == _Phase.pickStart) {
      setState(() { _start = pt; _phase = _Phase.pickEnd; });
    } else if (_phase == _Phase.pickEnd) {
      setState(() => _end = pt);
      _fetchRoadRoute();
    }
    _mapController.move(LatLng(pt.latitude, pt.longitude), 13);
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: AppColors.textPrimary)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currentLoc = _simState?.currentLocation ?? _start;
    final polylinePoints = _roadWaypoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final isRunning = _phase == _Phase.simulating;
    final progress = _simState?.progress ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Full-screen map ───────────────────────────────────────────────
          Positioned.fill(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(_start.latitude, _start.longitude),
                  initialZoom: MapService.defaultZoom,
                  minZoom: MapService.minZoom,
                  maxZoom: MapService.maxZoom,
                  onTap: (_, latlng) {
                    if (!isRunning && (_phase == _Phase.pickStart || _phase == _Phase.pickEnd)) {
                      _onMapTap(latlng);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: MapTypeOption.googleStandard.tileUrl,
                    subdomains: const ['0', '1', '2', '3'],
                    userAgentPackageName: MapService.userAgentPackageName,
                    maxZoom: MapService.maxZoom,
                  ),
                  if (polylinePoints.length >= 2)
                    PolylineLayer(polylines: [
                      Polyline(
                        points: polylinePoints,
                        strokeWidth: 5,
                        color: const Color(0xFF6C63FF),
                        borderStrokeWidth: 2,
                        borderColor: const Color(0x406C63FF),
                      ),
                    ]),
                  MarkerLayer(markers: [
                    // Start marker
                    Marker(
                      point: LatLng(_start.latitude, _start.longitude),
                      width: 44, height: 44,
                      child: _MapPin(color: AppColors.success, icon: Icons.trip_origin_rounded),
                    ),
                    // End marker
                    if (_end != null)
                      Marker(
                        point: LatLng(_end!.latitude, _end!.longitude),
                        width: 44, height: 44,
                        child: _MapPin(color: AppColors.error, icon: Icons.flag_rounded),
                      ),
                    // Current position (moving)
                    if (isRunning || _roadWaypoints.isNotEmpty)
                      Marker(
                        point: LatLng(currentLoc.latitude, currentLoc.longitude),
                        width: 48, height: 48,
                        child: _CarMarker(isMoving: isRunning),
                      ),
                  ]),
                ],
              ),
            ),
          ),

          // ── Top bar ───────────────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _GlassButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _GlassContainer(
                            child: Text(
                              _phaseLabel,
                              style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        if (_end != null) ...[
                          const SizedBox(width: 10),
                          _GlassButton(icon: Icons.refresh_rounded, onTap: _resetRoute),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Search bar
                    _GlassContainer(
                      padding: EdgeInsets.zero,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _search,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: _phase == _Phase.pickStart
                              ? 'Search start location...'
                              : 'Search destination...',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                          prefixIcon: _isSearching
                              ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                              : const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                                  onPressed: () { _searchCtrl.clear(); setState(() => _searchResults = []); })
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    if (_searchResults.isNotEmpty)
                      _GlassContainer(
                        padding: EdgeInsets.zero,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _searchResults.take(5).length,
                          separatorBuilder: (context, _) => const Divider(height: 1, color: AppColors.border),
                          itemBuilder: (_, i) {
                            final r = _searchResults[i];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.place_rounded, color: AppColors.primary, size: 18),
                              title: Text(r.displayName, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                              subtitle: Text('${r.latitude.toStringAsFixed(4)}, ${r.longitude.toStringAsFixed(4)}',
                                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                              onTap: () => _selectSearchResult(r),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Loading overlay ───────────────────────────────────────────────
          if (_isFetchingRoute)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: Center(
                  child: _GlassContainer(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                      const SizedBox(height: 14),
                      Text('Fetching road route...', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              ),
            ),

          // ── Bottom control sheet ──────────────────────────────────────────
          if (_phase == _Phase.preview || _phase == _Phase.simulating)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, -4))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route summary row
                      Row(children: [
                        _RouteEndpointBadge(label: 'FROM', point: _start, color: AppColors.success),
                        Expanded(child: Container(height: 1.5, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 8))),
                        _RouteEndpointBadge(label: 'TO', point: _end!, color: AppColors.error),
                      ]),
                      const SizedBox(height: 16),

                      // Progress bar (only when simulating)
                      if (_phase == _Phase.simulating) ...[
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Progress', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          Text('${(progress * 100).toStringAsFixed(1)}%', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Speed slider
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Speed', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        Text('${_speedKmh.toInt()} km/h', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ]),
                      Slider(
                        value: _speedKmh,
                        min: 5, max: 120, divisions: 23,
                        onChanged: isRunning ? null : (v) { setState(() => _speedKmh = v); },
                        onChangeEnd: isRunning ? null : (_) => _fetchRoadRoute(),
                      ),
                      const SizedBox(height: 8),

                      // Error banner
                      if (_routeError != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_routeError!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.error))),
                          ]),
                        ),

                      // Action buttons
                      Row(children: [
                        Expanded(child: GestureDetector(
                          onTap: isRunning ? _stopSimulation : _startSimulation,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: isRunning ? null : const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight]),
                              color: isRunning ? AppColors.error.withValues(alpha: 0.15) : null,
                              borderRadius: BorderRadius.circular(14),
                              border: isRunning ? Border.all(color: AppColors.error.withValues(alpha: 0.5)) : null,
                              boxShadow: isRunning ? [] : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
                            ),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded, color: isRunning ? AppColors.error : Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(isRunning ? 'Stop' : 'Start Drive', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: isRunning ? AppColors.error : Colors.white)),
                            ]),
                          ),
                        )),
                        if (!isRunning) ...[
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _resetRoute,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
                            ),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String get _phaseLabel {
    switch (_phase) {
      case _Phase.pickStart: return 'Tap map to set start point';
      case _Phase.pickEnd:   return _end == null ? 'Tap map to set destination' : 'Fetching road route…';
      case _Phase.preview:   return 'Route ready — set speed & start';
      case _Phase.simulating: return 'Driving… ${(_simState?.progress ?? 0) * 100 ~/ 1}% complete';
    }
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _GlassContainer({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10)],
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _MapPin({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)],
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

class _CarMarker extends StatefulWidget {
  final bool isMoving;
  const _CarMarker({required this.isMoving});
  @override
  State<_CarMarker> createState() => _CarMarkerState();
}

class _CarMarkerState extends State<_CarMarker> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => Transform.scale(
        scale: widget.isMoving ? _pulse.value : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: widget.isMoving ? 0.6 : 0.2), blurRadius: 14, spreadRadius: 2)],
          ),
          child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _RouteEndpointBadge extends StatelessWidget {
  final String label;
  final LocationPoint point;
  final Color color;
  const _RouteEndpointBadge({required this.label, required this.point, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 1)),
      const SizedBox(height: 2),
      Text(
        point.name ?? '${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)}',
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        maxLines: 1, overflow: TextOverflow.ellipsis,
      ),
    ]);
  }
}
