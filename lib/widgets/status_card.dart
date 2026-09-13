import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMocking ? Colors.green : Colors.grey,
                    boxShadow: isMocking
                        ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isMocking ? 'Mock Location: ON' : 'Mock Location: OFF',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isMocking ? Colors.green.shade800 : theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (onHelpTap != null)
                  IconButton(
                    icon: const Icon(Icons.help_outline, size: 20),
                    tooltip: 'How to Enable Mock Location',
                    onPressed: onHelpTap,
                  ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Coordinates',
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lat: ${currentLocation.latitude.toStringAsFixed(6)}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Lng: ${currentLocation.longitude.toStringAsFixed(6)}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (currentLocation.name != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentLocation.name!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    if (onDismissError != null)
                      GestureDetector(
                        onTap: onDismissError,
                        child: const Icon(Icons.close, color: Colors.red, size: 16),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
