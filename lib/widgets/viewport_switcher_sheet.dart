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
  final bool isNativeDevice;
  final double devicePixelRatio;
  final String formFactor;

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
    this.isNativeDevice = false,
    this.devicePixelRatio = 1.0,
    this.formFactor = 'standard',
  });

  bool get isNative => isNativeDevice;
}

/// Hardcoded simulated device profiles (non-native).
const simulatedDeviceProfiles = <SimulatedDeviceProfile>[
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
    formFactor: 'compact',
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
    formFactor: 'standard',
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
    formFactor: 'tablet',
  ),
];

/// Legacy constant — includes a placeholder native entry + simulated profiles.
/// Prefer using [simulatedDeviceProfiles] + the sensor-detected native profile.
const defaultDeviceProfiles = <SimulatedDeviceProfile>[
  SimulatedDeviceProfile(
    id: 'native',
    name: 'Native Device',
    description: 'Uses your actual phone hardware screen and cutouts',
    width: null,
    height: null,
    icon: Icons.phone_iphone_rounded,
    isNativeDevice: true,
  ),
  ...simulatedDeviceProfiles,
];

class ViewportSwitcherSheet extends StatelessWidget {
  final SimulatedDeviceProfile selected;
  final ValueChanged<SimulatedDeviceProfile> onSelect;

  /// The sensor-detected native device profile. When provided, it replaces
  /// the dumb placeholder "Native Device" entry with real hardware specs.
  final SimulatedDeviceProfile? nativeDevice;

  const ViewportSwitcherSheet({
    super.key,
    required this.selected,
    required this.onSelect,
    this.nativeDevice,
  });

  @override
  Widget build(BuildContext context) {
    final native = nativeDevice;

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
          // ── Drag Handle ──
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
            'Device Viewport',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // ── YOUR DEVICE Section ──
          if (native != null) ...[
            _SectionLabel(label: 'YOUR DEVICE'),
            const SizedBox(height: 8),
            _DeviceProfileTile(
              profile: native,
              isSelected: selected.isNative,
              isNativeHighlight: true,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(native);
              },
            ),
            const SizedBox(height: 16),
            _SectionLabel(label: 'SIMULATE ANOTHER'),
            const SizedBox(height: 8),
          ],

          // ── Simulated Profiles ──
          ...simulatedDeviceProfiles.map((profile) {
            final isSelected = selected.id == profile.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _DeviceProfileTile(
                profile: profile,
                isSelected: isSelected,
                isNativeHighlight: false,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(profile);
                },
              ),
            );
          }),

          // ── Fallback: show old native entry if no sensor ──
          if (native == null) ...[
            const SizedBox(height: 8),
            _DeviceProfileTile(
              profile: defaultDeviceProfiles.first,
              isSelected: selected.isNative,
              isNativeHighlight: false,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(defaultDeviceProfiles.first);
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Section Label ───────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppTheme.textMuted,
      ),
    );
  }
}

// ─── Device Profile Tile ─────────────────────────────────────────────

class _DeviceProfileTile extends StatelessWidget {
  final SimulatedDeviceProfile profile;
  final bool isSelected;
  final bool isNativeHighlight;
  final VoidCallback onTap;

  const _DeviceProfileTile({
    required this.profile,
    required this.isSelected,
    required this.isNativeHighlight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isNativeHighlight ? AppTheme.cyan : AppTheme.cyan;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.12)
                : AppTheme.previewSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : isNativeHighlight
                      ? AppTheme.borderGlow
                      : AppTheme.borderSubtle,
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                profile.icon,
                size: 20,
                color: isSelected ? accentColor : AppTheme.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (profile.formFactor.isNotEmpty &&
                            profile.formFactor != 'standard') ...[
                          const SizedBox(width: 6),
                          _FormFactorBadge(
                            label: profile.formFactor,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.description,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isSelected
                            ? accentColor.withValues(alpha: 0.8)
                            : AppTheme.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppTheme.cyan,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Form Factor Badge ───────────────────────────────────────────────

class _FormFactorBadge extends StatelessWidget {
  final String label;
  const _FormFactorBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.textMuted.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
