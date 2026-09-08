import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xE60A0A0A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isReloading
                    ? AppTheme.cyan
                    : AppTheme.previewBorder.withValues(alpha: 0.9),
                width: _isReloading ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isReloading
                      ? AppTheme.cyan.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.4),
                  blurRadius: _isReloading ? 18 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.isCliConnected ? AppTheme.cyan : AppTheme.warning,
                    shape: BoxShape.circle,
                    boxShadow: widget.isCliConnected
                        ? [BoxShadow(color: AppTheme.cyan.withValues(alpha: 0.6), blurRadius: 4)]
                        : null,
                  ),
                ).animate(target: _isReloading ? 1 : 0).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.6, 1.6),
                      duration: 200.ms,
                    ),
                const SizedBox(width: 6),
                Icon(
                  Icons.bolt_rounded,
                  size: 15,
                  color: widget.isCliConnected ? AppTheme.cyan : AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _isReloading ? 'Reloading...' : 'Reload',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _isReloading ? AppTheme.cyan : Colors.white,
                    letterSpacing: -0.2,
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
