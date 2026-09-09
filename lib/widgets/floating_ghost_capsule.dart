import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class FloatingGhostCapsule extends StatefulWidget {
  final VoidCallback onHotReload;
  final VoidCallback onOpenMenu;
  final VoidCallback? onOpenTerminal;
  final VoidCallback? onAnnotateBug;
  final bool isCliConnected;

  const FloatingGhostCapsule({
    super.key,
    required this.onHotReload,
    required this.onOpenMenu,
    this.onOpenTerminal,
    this.onAnnotateBug,
    this.isCliConnected = true,
  });

  @override
  State<FloatingGhostCapsule> createState() => _FloatingGhostCapsuleState();
}

class _FloatingGhostCapsuleState extends State<FloatingGhostCapsule> {
  static const _dyPrefKey = 'previewport_capsule_dy';
  static const _sidePrefKey = 'previewport_capsule_is_right';

  double _dy = 0.75; // Normalized vertical position (0.0 to 1.0)
  bool _isRightSide = true;
  bool _isInteracting = false;
  bool _isReloading = false;
  Timer? _dimTimer;
  double _opacity = 0.88;

  @override
  void initState() {
    super.initState();
    _resetDimTimer();
    _loadSavedPosition();
  }

  Future<void> _loadSavedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDy = prefs.getDouble(_dyPrefKey);
      final savedSide = prefs.getBool(_sidePrefKey);
      if (mounted) {
        setState(() {
          if (savedDy != null) _dy = savedDy.clamp(0.0, 1.0);
          if (savedSide != null) _isRightSide = savedSide;
        });
      }
    } catch (_) {}
  }

  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_dyPrefKey, _dy);
      await prefs.setBool(_sidePrefKey, _isRightSide);
    } catch (_) {}
  }

  @override
  void dispose() {
    _dimTimer?.cancel();
    super.dispose();
  }

  void _resetDimTimer() {
    _dimTimer?.cancel();
    if (_opacity < 0.85) {
      setState(() => _opacity = 0.88);
    }
    _dimTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isInteracting) {
        setState(() => _opacity = 0.22);
      }
    });
  }

  void _triggerReload() {
    _resetDimTimer();
    setState(() => _isReloading = true);
    widget.onHotReload();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isReloading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;
    final topPadding = mq.padding.top + 50;
    final bottomPadding = mq.padding.bottom + 60;
    final availableH = screenH - topPadding - bottomPadding;

    final currentY = topPadding + (_dy * availableH).clamp(0.0, availableH);

    return Positioned(
      top: currentY,
      right: _isRightSide ? 14 : null,
      left: !_isRightSide ? 14 : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          _dimTimer?.cancel();
          setState(() {
            _isInteracting = true;
            _opacity = 0.95;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            final newY = (currentY + details.delta.dy - topPadding) / availableH;
            _dy = newY.clamp(0.0, 1.0);
            if (details.globalPosition.dx < screenW * 0.4) {
              _isRightSide = false;
            } else if (details.globalPosition.dx > screenW * 0.6) {
              _isRightSide = true;
            }
          });
        },
        onPanEnd: (_) {
          setState(() => _isInteracting = false);
          _resetDimTimer();
          _savePosition();
        },
        onTap: _triggerReload,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          _resetDimTimer();
          widget.onOpenMenu();
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
            // Swipe up opens dev menu
            HapticFeedback.mediumImpact();
            widget.onOpenMenu();
          }
        },
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xF2101216),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isReloading
                    ? AppTheme.cyan
                    : const Color(0x33FFFFFF),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5.5,
                  height: 5.5,
                  decoration: BoxDecoration(
                    color: widget.isCliConnected ? AppTheme.cyan : AppTheme.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  PhosphorIconsRegular.lightning,
                  size: 14,
                  color: _isReloading
                      ? AppTheme.cyan
                      : (widget.isCliConnected ? Colors.white : AppTheme.textSecondary),
                ),
                const SizedBox(width: 5),
                Text(
                  _isReloading ? 'Reloading...' : 'Reload',
                  style: AppTypography.button(
                    fontSize: 11,
                    color: _isReloading ? AppTheme.cyan : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
