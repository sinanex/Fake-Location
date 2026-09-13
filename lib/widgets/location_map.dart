import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_point.dart';
import '../services/geocoding_service.dart';
import '../services/map_service.dart';

class LocationMap extends StatefulWidget {
  final LocationPoint currentLocation;
  final bool isMockActive;
  final Function(LocationPoint location) onLocationSelected;
  final List<LocationPoint>? routeWaypoints;
  final int? currentRouteIndex;

  const LocationMap({
    super.key,
    required this.currentLocation,
    required this.isMockActive,
    required this.onLocationSelected,
    this.routeWaypoints,
    this.currentRouteIndex,
  });

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  final MapController _mapController = MapController();
  final GeocodingService _geocodingService = GeocodingService();
  final TextEditingController _searchController = TextEditingController();

  List<GeocodingSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  Timer? _debounceTimer;

  @override
  void didUpdateWidget(covariant LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation != widget.currentLocation) {
      _animatedMapMove(
        LatLng(widget.currentLocation.latitude, widget.currentLocation.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    try {
      _mapController.move(destLocation, destZoom);
    } catch (_) {
      // Ignore initial render controller unattached errors
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      final results = await _geocodingService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _showSearchResults = true;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSearchResult(GeocodingSearchResult result) {
    final location = result.toLocationPoint();
    _searchController.text = result.displayName;
    setState(() {
      _showSearchResults = false;
    });
    widget.onLocationSelected(location);
    _animatedMapMove(LatLng(location.latitude, location.longitude), 14.0);
  }

  @override
  Widget build(BuildContext context) {
    final centerLatLng = LatLng(widget.currentLocation.latitude, widget.currentLocation.longitude);

    // Build route polyline points if provided
    final List<LatLng> polylinePoints = widget.routeWaypoints
            ?.map((p) => LatLng(p.latitude, p.longitude))
            .toList() ??
        [];

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerLatLng,
              initialZoom: MapService.defaultZoom,
              minZoom: MapService.minZoom,
              maxZoom: MapService.maxZoom,
              onTap: (tapPosition, latLng) {
                FocusScope.of(context).unfocus();
                setState(() => _showSearchResults = false);
                widget.onLocationSelected(LocationPoint(
                  latitude: latLng.latitude,
                  longitude: latLng.longitude,
                  name: 'Tapped Location',
                ));
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapService.openStreetMapTileUrl,
                userAgentPackageName: MapService.userAgentPackageName,
              ),
              if (polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 4.0,
                      color: Colors.indigo.shade600,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Start route marker
                  if (widget.routeWaypoints != null && widget.routeWaypoints!.isNotEmpty)
                    Marker(
                      point: LatLng(widget.routeWaypoints!.first.latitude,
                          widget.routeWaypoints!.first.longitude),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.trip_origin, color: Colors.green, size: 28),
                    ),

                  // Destination route marker
                  if (widget.routeWaypoints != null && widget.routeWaypoints!.length > 1)
                    Marker(
                      point: LatLng(widget.routeWaypoints!.last.latitude,
                          widget.routeWaypoints!.last.longitude),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.flag_rounded, color: Colors.red, size: 28),
                    ),

                  // Active mock location marker
                  Marker(
                    point: centerLatLng,
                    width: 120,
                    height: 80,
                    child: MapService.buildLocationMarker(
                      isMockActive: widget.isMockActive,
                      label: widget.currentLocation.name,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Search Overlay
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search city or place (e.g. Kochi, Delhi)...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults = [];
                                    _showSearchResults = false;
                                  });
                                },
                              )
                            : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),

              // Search results list
              if (_showSearchResults && _searchResults.isNotEmpty)
                Card(
                  elevation: 6,
                  margin: const EdgeInsets.only(top: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_city, color: Colors.indigo),
                        title: Text(
                          item.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          '${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () => _selectSearchResult(item),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // Recenter FAB
        Positioned(
          bottom: 12,
          right: 12,
          child: FloatingActionButton.small(
            heroTag: 'recenter_fab',
            onPressed: () => _animatedMapMove(centerLatLng, MapService.defaultZoom),
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
