import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart' show AppColors;
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

  static const _presets = [
    ('🇮🇳 Kochi', 9.9312, 76.2673),
    ('🇮🇳 Calicut', 11.2588, 75.7804),
    ('🇮🇳 Bangalore', 12.9716, 77.5946),
    ('🇮🇳 Delhi', 28.6139, 77.2090),
    ('🇬🇧 London', 51.5074, -0.1278),
    ('🇺🇸 New York', 40.7128, -74.0060),
    ('🇯🇵 Tokyo', 35.6762, 139.6503),
  ];

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
    _latController.text = lat.toStringAsFixed(6);
    _lngController.text = lng.toStringAsFixed(6);
    widget.onLocationSet(LocationPoint(latitude: lat, longitude: lng, name: name));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coordinates',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _CoordField(
                  controller: _latController,
                  label: 'Latitude',
                  hint: '±90.000000',
                  icon: Icons.north_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final lat = double.tryParse(v.trim());
                    if (lat == null) return 'Invalid number';
                    if (!LocationPoint.isValidLatitude(lat)) return '−90 to 90';
                    return null;
                  },
                )),
                const SizedBox(width: 10),
                Expanded(child: _CoordField(
                  controller: _lngController,
                  label: 'Longitude',
                  hint: '±180.000000',
                  icon: Icons.east_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final lng = double.tryParse(v.trim());
                    if (lng == null) return 'Invalid number';
                    if (!LocationPoint.isValidLongitude(lng)) return '−180 to 180';
                    return null;
                  },
                )),
              ],
            ),
            const SizedBox(height: 12),
            // Set Location gradient button
            GestureDetector(
              onTap: _submitForm,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.my_location_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Set Location',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Preset row
            Text(
              'Quick Presets',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presets.map((p) => _PresetChip(
                  label: p.$1,
                  onTap: () => _applyPreset(p.$1, p.$2, p.$3),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?) validator;

  const _CoordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 16, color: AppColors.primary),
        isDense: true,
        errorStyle: GoogleFonts.inter(fontSize: 10, color: AppColors.error),
      ),
      validator: validator,
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
