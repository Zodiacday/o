import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_theme.dart';

class DevMenuContent extends StatelessWidget {
  final String? title;
  final bool isCliConnected;
  final int terminalLogCount;
  final String selectedDeviceName;
  final IconData selectedDeviceIcon;
  final VoidCallback onHotReload;
  final VoidCallback onRestart;
  final VoidCallback onOpenViewportSwitcher;
  final VoidCallback onOpenTerminal;
  final VoidCallback onClearCache;
  final VoidCallback onExit;

  const DevMenuContent({
    super.key,
    required this.title,
    required this.isCliConnected,
    required this.terminalLogCount,
    required this.selectedDeviceName,
    required this.selectedDeviceIcon,
    required this.onHotReload,
    required this.onRestart,
    required this.onOpenViewportSwitcher,
    required this.onOpenTerminal,
    required this.onClearCache,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: CLI status hardware capsule & optional custom title
          Padding(
            padding: const EdgeInsets.only(right: 22.0, top: 2.0),
            child: Column(
              key: const Key('liquid_menu_title'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title?.trim().isNotEmpty == true) ...[
                  Text(
                    title!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sectionHud(color: Colors.white).copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCliConnected
                        ? AppTheme.cyan.withValues(alpha: 0.14)
                        : AppTheme.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCliConnected
                          ? AppTheme.cyan.withValues(alpha: 0.40)
                          : AppTheme.warning.withValues(alpha: 0.40),
                      width: 0.75,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCliConnected ? AppTheme.cyan : AppTheme.warning,
                            boxShadow: [
                              BoxShadow(
                                color: (isCliConnected ? AppTheme.cyan : AppTheme.warning)
                                    .withValues(alpha: 0.65),
                                blurRadius: 4,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4.5),
                        Text(
                          isCliConnected ? 'CLI LIVE' : 'CLI OFFLINE',
                          style: AppTypography.monoData(
                            fontSize: 8.0,
                            color: isCliConnected ? AppTheme.cyan : AppTheme.warning,
                          ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 1. Hot Reload (Hero Action: Solo at top, luminous cyan or amber glow)
          _GlassButton(
            label: 'HOT RELOAD',
            icon: PhosphorIconsRegular.arrowClockwise,
            onTap: onHotReload,
            isHero: true,
            heroColor: isCliConnected ? AppTheme.cyan : AppTheme.warning,
            height: 42,
            trailing: !isCliConnected
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.warning.withValues(alpha: 0.35),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      'OFFLINE',
                      style: AppTypography.monoData(
                        fontSize: 7.5,
                        color: AppTheme.warning,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 6),

          // 2. Full Restart
          _GlassButton(
            label: 'RESTART',
            icon: PhosphorIconsRegular.arrowsClockwise,
            onTap: onRestart,
            height: 38,
          ),
          const SizedBox(height: 6),

          // 3. Viewport switcher (with right chevron)
          _GlassButton(
            label: 'VIEWPORT',
            icon: selectedDeviceIcon,
            onTap: onOpenViewportSwitcher,
            height: 38,
            trailing: const Icon(
              PhosphorIconsRegular.caretRight,
              size: 12,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 6),

          // 4. Terminal console (with status-responsive monospace badge pill)
          _GlassButton(
            label: 'TERMINAL',
            icon: PhosphorIconsRegular.terminalWindow,
            onTap: onOpenTerminal,
            height: 38,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: (isCliConnected ? AppTheme.cyan : AppTheme.warning)
                    .withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (isCliConnected ? AppTheme.cyan : AppTheme.warning)
                      .withValues(alpha: 0.35),
                  width: 0.6,
                ),
              ),
              child: Text(
                '$terminalLogCount',
                style: AppTypography.monoData(
                  fontSize: 8.5,
                  color: isCliConnected ? AppTheme.cyan : AppTheme.warning,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // 5. Clear Cache
          _GlassButton(
            label: 'CLEAR CACHE',
            icon: PhosphorIconsRegular.trash,
            onTap: onClearCache,
            height: 38,
          ),
          const SizedBox(height: 10),

          // 6. Exit (Guarded destructive row: crimson glass, danger accent)
          _GlassButton(
            label: 'EXIT',
            icon: PhosphorIconsRegular.signOut,
            onTap: onExit,
            isDanger: true,
            height: 38,
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double height;
  final bool isHero;
  final Color? heroColor;
  final bool isDanger;
  final Widget? trailing;

  const _GlassButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.height = 38,
    this.isHero = false,
    this.heroColor,
    this.isDanger = false,
    this.trailing,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final activeHeroColor = widget.heroColor ?? AppTheme.cyan;
    final Color textColor = widget.isDanger
        ? AppTheme.danger
        : (widget.isHero ? activeHeroColor : Colors.white.withValues(alpha: 0.94));

    final Color iconColor = widget.isDanger
        ? AppTheme.danger
        : (widget.isHero ? activeHeroColor : Colors.white.withValues(alpha: 0.85));

    final List<Color> gradientColors = widget.isHero
        ? [
            activeHeroColor.withValues(alpha: 0.24),
            activeHeroColor.withValues(alpha: 0.08),
          ]
        : (widget.isDanger
            ? [
                const Color(0x2CFA3E3E),
                const Color(0x12FA3E3E),
              ]
            : [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.04),
              ]);

    final Color borderColor = widget.isHero
        ? activeHeroColor.withValues(alpha: 0.50)
        : (widget.isDanger
            ? AppTheme.danger.withValues(alpha: 0.42)
            : Colors.white.withValues(alpha: 0.18));

    final List<BoxShadow> shadows = widget.isHero
        ? [
            BoxShadow(
              color: activeHeroColor.withValues(alpha: 0.26),
              blurRadius: 12,
              spreadRadius: -1,
            ),
            const BoxShadow(
              color: Color(0x35000000),
              blurRadius: 4,
              offset: Offset(0, 1.5),
            ),
          ]
        : (widget.isDanger
            ? [
                BoxShadow(
                  color: AppTheme.danger.withValues(alpha: 0.20),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
                const BoxShadow(
                  color: Color(0x35000000),
                  blurRadius: 4,
                  offset: Offset(0, 1.5),
                ),
              ]
            : [
                const BoxShadow(
                  color: Color(0x30000000),
                  blurRadius: 4,
                  offset: Offset(0, 1.5),
                ),
              ]);

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: borderColor,
            width: 0.8,
          ),
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (val) {
              if (mounted && _isPressed != val) {
                setState(() => _isPressed = val);
              }
            },
            borderRadius: BorderRadius.circular(11),
            splashColor: widget.isHero
                ? activeHeroColor.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.10),
            highlightColor: Colors.transparent,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(
                  widget.icon,
                  size: widget.isHero ? 16.0 : 15.0,
                  color: iconColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.button(
                      fontSize: widget.isHero ? 9.8 : 9.2,
                      color: textColor,
                    ).copyWith(
                      fontWeight: widget.isHero ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: widget.isHero ? 0.4 : 0.2,
                    ),
                  ),
                ),
                if (widget.trailing != null) ...[
                  widget.trailing!,
                  const SizedBox(width: 8),
                ] else
                  const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
