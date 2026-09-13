import 'package:flutter/material.dart';

class MapService {
  static const String openStreetMapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String userAgentPackageName = 'com.example.mock_location_app';

  static const double defaultZoom = 13.0;
  static const double maxZoom = 18.0;
  static const double minZoom = 3.0;

  /// Custom marker builder with animated pulsing circle for current selected mock location
  static Widget buildLocationMarker({
    required bool isMockActive,
    String? label,
    Color color = Colors.redAccent,
  }) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null && label.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              if (isMockActive)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.4),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent.withValues(alpha: 0.35),
                        ),
                      ),
                    );
                  },
                ),
              Icon(
                Icons.location_on,
                size: 38,
                color: isMockActive ? Colors.green : color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
