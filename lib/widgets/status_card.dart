import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart' show AppColors;
import '../models/location_point.dart';

class StatusCard extends StatelessWidget {
  final bool isMocking;
  final LocationPoint currentLocation;
  final String? errorMessage;
  final VoidCallback? onDismissError;
  final VoidCallback? onHelpTap;

  const StatusCard({
    super.key,
    required this.isMocking,
    required this.currentLocation,
    this.errorMessage,
    this.onDismissError,
    this.onHelpTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMocking
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMocking ? 'Mock Active' : 'Mock Inactive',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isMocking ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                    if (currentLocation.name != null && currentLocation.name!.isNotEmpty)
                      Text(
                        currentLocation.name!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (onHelpTap != null)
                GestureDetector(
                  onTap: onHelpTap,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Coordinate pills
          Row(
            children: [
              _CoordPill(label: 'LAT', value: currentLocation.latitude.toStringAsFixed(6)),
              const SizedBox(width: 8),
              _CoordPill(label: 'LNG', value: currentLocation.longitude.toStringAsFixed(6)),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: GoogleFonts.inter(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                  if (onDismissError != null)
                    GestureDetector(
                      onTap: onDismissError,
                      child: const Icon(Icons.close_rounded, color: AppColors.error, size: 16),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CoordPill extends StatelessWidget {
  final String label;
  final String value;
  const _CoordPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(
              fontSize: 9, fontWeight: FontWeight.w700,
              color: AppColors.primary, letterSpacing: 1.2,
            )),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
          ],
        ),
      ),
    );
  }
}
