import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';

class NavItemData {
  final IconData icon;
  final String label;

  const NavItemData({required this.icon, required this.label});
}

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  static const List<NavItemData> navItems = [
    NavItemData(icon: LucideIcons.scan_qr_code, label: 'Scanner'),
    NavItemData(icon: LucideIcons.clock, label: 'History'),
    NavItemData(icon: LucideIcons.zap, label: 'Connect'),
    NavItemData(icon: LucideIcons.sliders_horizontal, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final itemWidth = (totalWidth - 8) / navItems.length;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 60,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xF2080B11), // Matte Frosted OLED chassis
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF1E2638), // Precision hairline slate border
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Option B: Matte Segmented Pill Sliding Indicator (Zero Neon Glow)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    left: currentIndex * itemWidth,
                    top: 0,
                    bottom: 0,
                    width: itemWidth,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131A26), // Solid matte dark slate
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF263347), // Milled slate hairline
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Interactive Nav Item Icons & Labels with Tactile Haptics
                  Row(
                    children: navItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isSelected = currentIndex == index;

                      return Expanded(
                        child: Bounceable(
                          scaleFactor: 0.92,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTabSelected(index);
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: isSelected ? 1.05 : 1.0,
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOutCubic,
                                  child: Icon(
                                    item.icon,
                                    size: isSelected ? 20 : 18,
                                    color: isSelected
                                        ? const Color(0xFF00E5FF)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                    letterSpacing: isSelected ? 0.2 : 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
