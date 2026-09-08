import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MockLocationPreset {
  final String id;
  final String title;
  final String subtitle;
  final double? latitude;
  final double? longitude;
  final IconData icon;

  const MockLocationPreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    required this.icon,
  });

  bool get isRealGps => latitude == null || longitude == null;
}

const defaultLocationPresets = <MockLocationPreset>[
  MockLocationPreset(
    id: 'real_gps',
    title: 'Real Hardware GPS',
    subtitle: 'Uses phone live satellite & sensor location',
    latitude: null,
    longitude: null,
    icon: Icons.my_location_rounded,
  ),
  MockLocationPreset(
    id: 'apple_park',
    title: 'Apple Park, Cupertino',
    subtitle: '37.3349° N, 122.0090° W',
    latitude: 37.3349,
    longitude: -122.0090,
    icon: Icons.business_rounded,
  ),
  MockLocationPreset(
    id: 'tokyo',
    title: 'Shibuya, Tokyo',
    subtitle: '35.6595° N, 139.7004° E',
    latitude: 35.6595,
    longitude: 139.7004,
    icon: Icons.location_city_rounded,
  ),
  MockLocationPreset(
    id: 'london',
    title: 'Westminster, London',
    subtitle: '51.5007° N, 0.1246° W',
    latitude: 51.5007,
    longitude: -0.1246,
    icon: Icons.nature_people_rounded,
  ),
  MockLocationPreset(
    id: 'new_york',
    title: 'Manhattan, New York',
    subtitle: '40.7580° N, 73.9855° W',
    latitude: 40.7580,
    longitude: -73.9855,
    icon: Icons.apartment_rounded,
  ),
];

class LocationMockSheet extends StatelessWidget {
  final MockLocationPreset selected;
  final ValueChanged<MockLocationPreset> onSelect;
  final void Function(double lat, double lng, String name) onCustom;

  const LocationMockSheet({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0C0C0C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.previewBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Simulate Location',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => _showCustomDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.previewSurfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.previewBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_location_alt_rounded,
                          size: 13, color: AppTheme.cyan),
                      const SizedBox(width: 4),
                      Text(
                        'Custom Lat/Lng',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.cyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'GPS coordinates returned to navigator.geolocation in the preview.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...defaultLocationPresets.map((preset) {
            final isSelected = selected.id == preset.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(preset);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.cyan.withValues(alpha: 0.12)
                          : AppTheme.previewSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.cyan
                            : AppTheme.borderSubtle,
                        width: isSelected ? 1.4 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          preset.icon,
                          size: 18,
                          color: isSelected
                              ? AppTheme.cyan
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset.title,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                preset.subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: isSelected
                                      ? AppTheme.cyan.withValues(alpha: 0.8)
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: AppTheme.cyan,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showCustomDialog(BuildContext context) {
    final latController = TextEditingController();
    final lngController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Custom Coordinates',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Latitude (e.g. 37.7749)',
                labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF080808),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lngController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Longitude (e.g. -122.4194)',
                labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF080808),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              if (lat != null && lng != null) {
                Navigator.of(dialogCtx).pop();
                Navigator.of(context).pop();
                onCustom(lat, lng, 'Custom ($lat, $lng)');
              }
            },
            child: Text('Apply', style: GoogleFonts.inter(color: AppTheme.cyan, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
