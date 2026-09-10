import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../theme/app_theme.dart';

class NavItemData {
  final IconData icon;
  final String label;

  const NavItemData({required this.icon, required this.label});
}

/// A real floating iOS frosted glass pill navbar.
///
/// Features authentic Apple-grade optical layering:
/// - 24px backdrop Gaussian blur shader on GPU (Impeller)
/// - Semi-translucent dark glass wash with PreviewPort brand accents
/// - Precision beveled glass hairline border with specular highlight
/// - Floating luminous cyan liquid pill that glides smoothly behind the active tab
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  static const List<NavItemData> navItems = [
    NavItemData(icon: PhosphorIconsRegular.qrCode, label: 'Scanner'),
    NavItemData(icon: PhosphorIconsRegular.lightning, label: 'Connect'),
    NavItemData(icon: PhosphorIconsRegular.slidersHorizontal, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = currentIndex.clamp(0, navItems.length - 1);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.85),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0xFF1B2232),
                width: 0.85,
              ),
            ),
            child: Stack(
              children: [
                // 1. Sliding liquid cyan pill behind the active tab (borderless translucent wash)
                AnimatedAlign(
                  alignment: Alignment(-1.0 + (selectedIndex * 1.0), 0.0),
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: FractionallySizedBox(
                    widthFactor: 1 / navItems.length,
                    heightFactor: 1.0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.cyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                ),

                // 2. Interactive Navigation Items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: navItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = selectedIndex == index;

                    return Expanded(
                      child: Semantics(
                        button: true,
                        selected: isSelected,
                        label: item.label,
                        child: Bounceable(
                          key: ValueKey('navbar-${item.label.toLowerCase()}'),
                          scaleFactor: 0.92,
                          hitTestBehavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTabSelected(index);
                          },
                          child: SizedBox(
                            height: 64,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: isSelected ? 1.08 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  child: Icon(
                                    item.icon,
                                    size: isSelected ? 20 : 18,
                                    color: isSelected
                                        ? AppTheme.cyan
                                        : AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  style: AppTypography.navLabel(
                                    isSelected: isSelected,
                                  ),
                                  child: Text(item.label),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}
