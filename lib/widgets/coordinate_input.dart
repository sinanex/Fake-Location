import 'package:flutter/material.dart';
import '../models/location_point.dart';

class CoordinateInput extends StatefulWidget {
  final LocationPoint initialLocation;
  final Function(LocationPoint location) onLocationSet;

  const CoordinateInput({
    super.key,
    required this.initialLocation,
    required this.onLocationSet,
  });

  @override
  State<CoordinateInput> createState() => _CoordinateInputState();
}

class _CoordinateInputState extends State<CoordinateInput> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _latController;
  late TextEditingController _lngController;

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(text: widget.initialLocation.latitude.toString());
    _lngController = TextEditingController(text: widget.initialLocation.longitude.toString());
  }

  @override
  void didUpdateWidget(covariant CoordinateInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLocation != widget.initialLocation) {
      _latController.text = widget.initialLocation.latitude.toStringAsFixed(6);
      _lngController.text = widget.initialLocation.longitude.toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final lat = double.parse(_latController.text.trim());
      final lng = double.parse(_lngController.text.trim());

      widget.onLocationSet(LocationPoint(
        latitude: lat,
        longitude: lng,
        name: widget.initialLocation.name ?? 'Custom Location',
      ));
    }
  }

  void _applyPreset(String name, double lat, double lng) {
    setState(() {
      _latController.text = lat.toString();
      _lngController.text = lng.toString();
    });
    widget.onLocationSet(LocationPoint(latitude: lat, longitude: lng, name: name));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coordinates Input',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        hintText: '-90.0 to 90.0',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        prefixIcon: Icon(Icons.location_searching, size: 20),
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Latitude is required';
                        }
                        final lat = double.tryParse(value.trim());
                        if (lat == null) {
                          return 'Enter a valid number';
                        }
                        if (!LocationPoint.isValidLatitude(lat)) {
                          return 'Must be -90 to 90';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        hintText: '-180.0 to 180.0',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        prefixIcon: Icon(Icons.explore, size: 20),
                        isDense: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Longitude is required';
                        }
                        final lng = double.tryParse(value.trim());
                        if (lng == null) {
                          return 'Enter a valid number';
                        }
                        if (!LocationPoint.isValidLongitude(lng)) {
                          return 'Must be -180 to 180';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Set Location'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Quick Presets:',
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip('Kochi', 9.9312, 76.2673),
                    _buildPresetChip('Calicut', 11.2588, 75.7804),
                    _buildPresetChip('Bangalore', 12.9716, 77.5946),
                    _buildPresetChip('Delhi', 28.6139, 77.2090),
                    _buildPresetChip('London', 51.5074, -0.1278),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String name, double lat, double lng) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        label: Text(name, style: const TextStyle(fontSize: 11)),
        avatar: const Icon(Icons.pin_drop, size: 14),
        onPressed: () => _applyPreset(name, lat, lng),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
