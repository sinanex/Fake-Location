import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/mock_location_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final MockLocationService _mockService = MockLocationService();
  PermissionStatus? _locationPermissionStatus;
  bool? _isMockLocationAllowed;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final status = await Permission.location.status;
    final isMockAllowed = await _mockService.isMockLocationEnabled();

    if (mounted) {
      setState(() {
        _locationPermissionStatus = status;
        _isMockLocationAllowed = isMockAllowed;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (mounted) {
      setState(() => _locationPermissionStatus = status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Options & Setup'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: Colors.indigo, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Educational Tool',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'This app uses official Android LocationManager APIs to demonstrate native mock provider injection.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Diagnostic Status Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'System Diagnostics',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _checkStatus,
                          tooltip: 'Re-check status',
                        ),
                      ],
                    ),
                    const Divider(),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _locationPermissionStatus?.isGranted == true
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: _locationPermissionStatus?.isGranted == true
                            ? Colors.green
                            : Colors.orange,
                      ),
                      title: const Text('App Location Permission'),
                      subtitle: Text(_locationPermissionStatus?.toString() ?? 'Unknown'),
                      trailing: _locationPermissionStatus?.isGranted != true
                          ? TextButton(
                              onPressed: _requestLocationPermission,
                              child: const Text('Grant'),
                            )
                          : null,
                    ),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _isMockLocationAllowed == true ? Icons.check_circle : Icons.info_outline,
                        color: _isMockLocationAllowed == true ? Colors.green : Colors.grey,
                      ),
                      title: const Text('Android Mock Location App Status'),
                      subtitle: Text(_isMockLocationAllowed == true
                          ? 'Mock Provider Active'
                          : 'Not active or needs Developer Options setup'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Setup Guide
            Text(
              'How to Enable Mock Location',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStepTile(
              stepNumber: '1',
              title: 'Open Android Settings',
              description: 'Go to Settings on your Android test device or emulator.',
              icon: Icons.settings,
            ),
            _buildStepTile(
              stepNumber: '2',
              title: 'Enable Developer Options',
              description:
                  'Go to Settings → About Phone → Tap "Build Number" 7 times until you see "You are now a developer!".',
              icon: Icons.developer_mode,
            ),
            _buildStepTile(
              stepNumber: '3',
              title: 'Select Mock Location App',
              description:
                  'Go to Settings → System → Developer Options → "Select mock location app" (or "Allow mock locations").',
              icon: Icons.touch_app,
            ),
            _buildStepTile(
              stepNumber: '4',
              title: 'Choose This Application',
              description: 'Select "mock_location_app" from the list of available mock apps.',
              icon: Icons.check_box_outlined,
            ),
            const SizedBox(height: 20),

            // Disclaimer Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, color: Colors.amber, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Android security prevents apps from spoofing location unless explicitly selected by the user in Developer Options. This is by design.',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTile({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.indigo,
            child: Text(
              stepNumber,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: Colors.indigo),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
