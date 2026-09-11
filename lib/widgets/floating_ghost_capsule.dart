import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// An edge-docked developer control system featuring a 25% radial bezel dial
/// and two satellite action buttons (⚡ Hot Reload and 🛠️ Dev Menu).
///
/// Built with solid obsidian materials, single continuous luminous cyan arc line,
/// and a physics-driven morphing animation on open and close.
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

class _FloatingGhostCapsuleState extends State<FloatingGhostCapsule>
    with SingleTickerProviderStateMixin {
  static const _dyPrefKey = 'previewport_capsule_dy';
  static const _sidePrefKey = 'previewport_capsule_is_right';

  // Sizing & geometry constants (refined Style 1 proportions)
  static const double _quadrantRadius = 44.0;
  static const double _quadrantHeight = 88.0;
  static const double _satelliteSize = 46.0;
  static const double _orbitRadius = 92.0;
  static const double _orbitAngleDeg = 38.0;

  // Solid color palette
  static const Color _obsidianSolid = Color(0xFF0B0E17);

  double _dy = 0.65; // Normalized vertical position (0.0 to 1.0)
  bool _isRightSide = true;
  bool _isInteracting = false;
  bool _isReloading = false;
  bool _isExpanded = false;
  Timer? _dimTimer;
  double _opacity = 0.92;

  late final AnimationController _morphController;
  late final Animation<double> _morphAnimation;
  late final Animation<double> _arcProgressAnimation;
  late final Animation<double> _hubRecoilAnimation;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 260),
    );

    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    _arcProgressAnimation = CurvedAnimation(
      parent: _morphController,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      reverseCurve: const Interval(0.15, 1.0, curve: Curves.easeInCubic),
    );

    _hubRecoilAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.92).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0).chain(CurveTween(curve: Curves.easeInBack)),
        weight: 65,
      ),
    ]).animate(CurvedAnimation(
      parent: _morphController,
      curve: const Interval(0.0, 0.45, curve: Curves.linear),
    ));

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
    _morphController.dispose();
    super.dispose();
  }

  void _resetDimTimer() {
    _dimTimer?.cancel();
    if (_opacity < 0.85) {
      setState(() => _opacity = 0.92);
    }
    _dimTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isInteracting && !_isExpanded) {
        setState(() => _opacity = 0.22);
      }
    });
  }

  void _expand() {
    _dimTimer?.cancel();
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = true;
      _opacity = 1.0;
    });
    _morphController.forward(from: 0.0);
  }

  void _collapse({VoidCallback? onCompleted}) {
    _morphController.reverse().then((_) {
      if (mounted) {
        setState(() => _isExpanded = false);
        _resetDimTimer();
        onCompleted?.call();
      }
    });
  }

  void _toggleExpansion() {
    if (_isExpanded) {
      _collapse();
    } else {
      _expand();
    }
  }

  void _triggerReloadFromSatellite() {
    HapticFeedback.mediumImpact();
    setState(() => _isReloading = true);
    widget.onHotReload();
    _collapse(onCompleted: () {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _isReloading = false);
      });
    });
  }

  void _triggerMenuFromSatellite() {
    HapticFeedback.lightImpact();
    _collapse(onCompleted: () {
      widget.onOpenMenu();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;

    // Guaranteed clearance so arc line & satellites never clip offscreen
    final topPadding = mq.padding.top + _orbitRadius + 16.0;
    final bottomPadding = mq.padding.bottom + _orbitRadius + 16.0;
    final availableH = (screenH - topPadding - bottomPadding).clamp(100.0, screenH);

    final currentY = topPadding + (_dy * availableH).clamp(0.0, availableH);

    if (_isExpanded) {
      return Positioned.fill(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Backdrop scrim dismisses on outside tap
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _collapse(),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.30),
                ),
              ),
            ),

            // Active morphing dial and satellites
            Positioned(
              top: currentY - (_quadrantHeight / 2),
              right: _isRightSide ? 0 : null,
              left: !_isRightSide ? 0 : null,
              child: _buildDialChassis(currentY, screenW, topPadding, availableH),
            ),
          ],
        ),
      );
    }

    // Collapsed idle state docked flush to screen bezel
    return Positioned(
      top: currentY - (_quadrantHeight / 2),
      right: _isRightSide ? 0 : null,
      left: !_isRightSide ? 0 : null,
      child: _buildDialChassis(currentY, screenW, topPadding, availableH),
    );
  }

  Widget _buildDialChassis(
    double currentY,
    double screenW,
    double topPadding,
    double availableH,
  ) {
    const totalBoxW = _orbitRadius + _satelliteSize + 16;
    const totalBoxH = (_orbitRadius * 2) + _satelliteSize + 16;

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        // When collapsed, tightly bound to the hub to prevent dead zones
        width: _isExpanded ? totalBoxW : _quadrantRadius,
        height: _isExpanded ? totalBoxH : _quadrantHeight,
        child: Stack(
          alignment: _isRightSide ? Alignment.centerRight : Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            // Morphing satellites & single continuous connecting arc
            if (_isExpanded)
              AnimatedBuilder(
                animation: _morphController,
                builder: (context, child) {
                  return _buildSatellitesAndMorphArc(totalBoxW, totalBoxH);
                },
              ),

            // The 25% edge quadrant (docked flush against the bezel)
            GestureDetector(
              key: const Key('radial_edge_quadrant'),
              behavior: HitTestBehavior.opaque,
              onTap: _toggleExpansion,
              onLongPress: () {
                HapticFeedback.mediumImpact();
                _dimTimer?.cancel();
                widget.onOpenMenu();
              },
              onPanStart: (_) {
                _dimTimer?.cancel();
                if (_isExpanded) {
                  _collapse();
                }
                setState(() {
                  _isInteracting = true;
                  _opacity = 1.0;
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
              child: AnimatedBuilder(
                animation: _hubRecoilAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scaleX: _hubRecoilAnimation.value,
                    alignment: _isRightSide ? Alignment.centerRight : Alignment.centerLeft,
                    child: _buildQuadrantBezel(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Solid-color 25% radial bezel docked on screen edge
  /// Minimalist obsidian body + crisp solid cyan hairline border
  Widget _buildQuadrantBezel() {
    final outerRadius = _isRightSide
        ? const BorderRadius.only(
            topLeft: Radius.circular(_quadrantRadius),
            bottomLeft: Radius.circular(_quadrantRadius),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(_quadrantRadius),
            bottomRight: Radius.circular(_quadrantRadius),
          );

    return Container(
      width: _quadrantRadius,
      height: _quadrantHeight,
      decoration: BoxDecoration(
        color: _obsidianSolid,
        borderRadius: outerRadius,
        border: Border.all(
          color: _isReloading
              ? AppTheme.cyan
              : (_isExpanded
                  ? AppTheme.cyan
                  : AppTheme.cyan.withValues(alpha: 0.80)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 14,
            offset: Offset(_isRightSide ? -3 : 3, 3),
          ),
          BoxShadow(
            color: AppTheme.cyan.withValues(alpha: _isExpanded || _isReloading ? 0.35 : 0.16),
            blurRadius: 12,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(
            left: _isRightSide ? 8 : 0,
            right: !_isRightSide ? 8 : 0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: widget.isCliConnected ? AppTheme.cyan : AppTheme.warning,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (widget.isCliConnected)
                      BoxShadow(
                        color: AppTheme.cyan.withValues(alpha: 0.8),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                PhosphorIconsRegular.lightning,
                size: 16,
                color: _isReloading
                    ? AppTheme.cyan
                    : (_isExpanded ? Colors.white : AppTheme.cyan),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Satellites blooming along the radial trajectory with the single connected arc line
  Widget _buildSatellitesAndMorphArc(double totalW, double totalH) {
    final progress = _morphAnimation.value;
    final arcProgress = _arcProgressAnimation.value;
    final angleRad = _orbitAngleDeg * math.pi / 180;

    // Anchor center on the screen bezel edge
    final anchorX = _isRightSide ? totalW : 0.0;
    final anchorY = totalH / 2;

    // Radial distance expands from 0 to full orbit radius
    final currentR = _orbitRadius * progress;

    // Satellite centers along the arc trajectory
    final double reloadCenterX = anchorX + (_isRightSide ? -1 : 1) * currentR * math.cos(angleRad);
    final double reloadCenterY = anchorY - currentR * math.sin(angleRad);

    final double menuCenterX = anchorX + (_isRightSide ? -1 : 1) * currentR * math.cos(angleRad);
    final double menuCenterY = anchorY + currentR * math.sin(angleRad);

    final double halfSat = _satelliteSize / 2;

    // Subtle rotational inertia during transit
    final iconRotation = (1.0 - progress.clamp(0.0, 1.0)) * 0.22;

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Single continuous luminous cyan arc line (from top bezel to bottom bezel)
          CustomPaint(
            size: Size(totalW, totalH),
            painter: _MorphingOrbitArcPainter(
              isRightSide: _isRightSide,
              progress: arcProgress,
              orbitRadius: _orbitRadius,
              lineColor: AppTheme.cyan,
            ),
          ),

          // 1. Top Satellite: Hot Reload (⚡)
          Positioned(
            left: reloadCenterX - halfSat,
            top: reloadCenterY - halfSat,
            child: Transform.scale(
              scale: progress.clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: -iconRotation,
                child: _buildSatelliteButton(
                  key: const Key('capsule_satellite_reload'),
                  icon: PhosphorIconsRegular.lightning,
                  iconColor: AppTheme.cyan,
                  tooltip: 'Hot Reload',
                  onTap: _triggerReloadFromSatellite,
                  isPulsing: _isReloading,
                ),
              ),
            ),
          ),

          // 2. Bottom Satellite: Dev Menu (🎛️)
          Positioned(
            left: menuCenterX - halfSat,
            top: menuCenterY - halfSat,
            child: Transform.scale(
              scale: progress.clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: iconRotation,
                child: _buildSatelliteButton(
                  key: const Key('capsule_satellite_menu'),
                  icon: PhosphorIconsRegular.slidersHorizontal,
                  iconColor: AppTheme.cyan,
                  tooltip: 'Dev Menu',
                  onTap: _triggerMenuFromSatellite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Solid-color circular satellite puck with crisp 1.2px cyan rim
  Widget _buildSatelliteButton({
    required Key key,
    required IconData icon,
    required Color iconColor,
    required String tooltip,
    required VoidCallback onTap,
    bool isPulsing = false,
  }) {
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: _satelliteSize,
          height: _satelliteSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _obsidianSolid,
            border: Border.all(
              color: isPulsing
                  ? AppTheme.cyan
                  : AppTheme.cyan.withValues(alpha: 0.85),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.70),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: AppTheme.cyan.withValues(alpha: isPulsing ? 0.60 : 0.25),
                blurRadius: isPulsing ? 18 : 10,
                spreadRadius: isPulsing ? 2.0 : 0.5,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: 21,
              color: iconColor,
              shadows: [
                Shadow(
                  color: AppTheme.cyan.withValues(alpha: 0.75),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter that renders exactly ONE continuous, elegant arc line
/// connecting from screen bezel edge (top) through the satellites and hub
/// to the screen bezel edge (bottom), unrolling dynamically with morph progress.
class _MorphingOrbitArcPainter extends CustomPainter {
  final bool isRightSide;
  final double progress;
  final double orbitRadius;
  final Color lineColor;

  _MorphingOrbitArcPainter({
    required this.isRightSide,
    required this.progress,
    required this.orbitRadius,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.02) return;

    final originX = isRightSide ? size.width : 0.0;
    final originY = size.height / 2;
    final center = Offset(originX, originY);

    final rect = Rect.fromCircle(center: center, radius: orbitRadius);

    // Continuous 180° semicircle arc rooted at the screen bezel:
    // Right side: Inward direction is left (angle = π). Sweeps between top (3π/2) and bottom (π/2).
    // Left side:  Inward direction is right (angle = 0). Sweeps between top (-π/2) and bottom (π/2).
    // The arc unrolls symmetrically outward from the center hub towards the bezel anchors.
    final double maxHalfSweep = math.pi / 2;
    final double halfSweep = maxHalfSweep * progress.clamp(0.0, 1.0);

    final double startAngle = isRightSide
        ? (math.pi - halfSweep)
        : (-halfSweep);
    final double sweepAngle = halfSweep * 2;

    // 1. Soft subtle luminous halo pass
    final glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.20 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // 2. Crisp, primary solid arc line
    final solidLinePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.85 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, solidLinePaint);
  }

  @override
  bool shouldRepaint(covariant _MorphingOrbitArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRightSide != isRightSide ||
        oldDelegate.orbitRadius != orbitRadius ||
        oldDelegate.lineColor != lineColor;
  }
}
