import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SimulatedDeviceProfile {
  final String id;
  final String name;
  final String description;
  final double? width;
  final double? height;
  final double topInset;
  final double bottomInset;
  final double cornerRadius;
  final bool hasDynamicIsland;
  final bool hasNotch;
  final IconData icon;

  const SimulatedDeviceProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.width,
    required this.height,
    this.topInset = 0,
    this.bottomInset = 0,
    this.cornerRadius = 0,
    this.hasDynamicIsland = false,
    this.hasNotch = false,
    required this.icon,
  });

  bool get isNative => width == null || height == null;
}

const defaultDeviceProfiles = <SimulatedDeviceProfile>[
  SimulatedDeviceProfile(
    id: 'native',
    name: 'Native Device',
    description: 'Uses your actual phone hardware screen and cutouts',
    width: null,
    height: null,
    icon: Icons.phone_iphone_rounded,
  ),
  SimulatedDeviceProfile(
    id: 'iphone_se',
    name: 'iPhone SE (Compact 4.7")',
    description: '375 × 667 pt • Classic 16:9 ratio with 20pt status bar',
    width: 375,
    height: 667,
    topInset: 20,
    bottomInset: 0,
    cornerRadius: 18,
    icon: Icons.phone_android_rounded,
  ),
  SimulatedDeviceProfile(
    id: 'android_punch_hole',
    name: 'Android Punch-Hole (6.2")',
    description: '412 × 915 pt • Centered camera cutout with gesture bar',
    width: 412,
    height: 915,
    topInset: 36,
    bottomInset: 16,
    cornerRadius: 28,
    hasNotch: true,
    icon: Icons.smartphone_rounded,
  ),
  SimulatedDeviceProfile(
    id: 'ipad_mini',
    name: 'iPad Mini (Tablet 8.3")',
    description: '744 × 1133 pt • Compact tablet responsive layout',
    width: 744,
    height: 1133,
    topInset: 24,
    bottomInset: 20,
    cornerRadius: 24,
    icon: Icons.tablet_mac_rounded,
  ),
];

class ViewportSwitcherSheet extends StatelessWidget {
  final SimulatedDeviceProfile selected;
  final ValueChanged<SimulatedDeviceProfile> onSelect;

  const ViewportSwitcherSheet({
    super.key,
    required this.selected,
    required this.onSelect,
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
          Text(
            'Device Viewport Simulator',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Simulate compact phones, punch-holes, or tablets right inside your iPhone.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...defaultDeviceProfiles.map((profile) {
            final isSelected = selected.id == profile.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(profile);
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
                          profile.icon,
                          size: 20,
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
                                profile.name,
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
                                profile.description,
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
}
