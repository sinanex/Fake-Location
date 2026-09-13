import 'package:flutter/material.dart';

class MockControlButtons extends StatelessWidget {
  final bool isMocking;
  final bool isLoading;
  final VoidCallback onStartMock;
  final VoidCallback onStopMock;
  final VoidCallback onOpenRouteSimulation;

  const MockControlButtons({
    super.key,
    required this.isMocking,
    required this.isLoading,
    required this.onStartMock,
    required this.onStopMock,
    required this.onOpenRouteSimulation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isLoading || isMocking ? null : onStartMock,
                icon: isLoading && !isMocking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(isMocking ? 'Mock Running' : 'Start Mock'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: isMocking ? 0 : 2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading || !isMocking ? null : onStopMock,
                icon: isLoading && isMocking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.stop_rounded),
                label: const Text('Stop Mock'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(
                    color: isMocking ? Colors.red.shade400 : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onOpenRouteSimulation,
            icon: const Icon(Icons.route_rounded, color: Colors.indigo),
            label: const Text(
              'Open Route Simulation',
              style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Colors.indigo, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
