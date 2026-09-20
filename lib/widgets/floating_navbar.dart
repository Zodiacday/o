import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class NavItemData {
  final IconData icon;
  final String label;

  const NavItemData({required this.icon, required this.label});
}

/// A quiet, dedicated navigation block.
///
/// Navigation is separated from the preview content by a single hairline and
/// a black surface. Selection remains intentionally light so the block does
/// not become a second hero section.
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
    NavItemData(icon: LucideIcons.sliders_horizontal, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = currentIndex.clamp(0, navItems.length - 1);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.previewBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
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
                            scale: isSelected ? 1.04 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              item.icon,
                              size: isSelected ? 20 : 18,
                              color: isSelected
                                  ? AppTheme.cyan
                                  : AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.textPrimary
                                  : AppTheme.textMuted,
                              letterSpacing: 0.05,
                            ),
                            child: Text(item.label),
                          ),
                          const SizedBox(height: 5),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            width: isSelected ? 14 : 0,
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppTheme.cyan,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
