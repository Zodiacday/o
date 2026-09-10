import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// An edge-docked 25% radial bezel dial that blooms two circular satellite
/// action buttons (⚡ Hot Reload and 🛠️ Dev Menu) into the screen upon tap,
/// featuring dual concentric neon arcs, glowing halo rings, and dotted orbit tracks.
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

  // Sizing constants matching high-fidelity mockup
  static const double _quadrantRadius = 48.0;
  static const double _quadrantHeight = 96.0;
  static const double _satelliteSize = 52.0;
  static const double _orbitRadius = 98.0;
  static const double _orbitAngleDeg = 36.0;

  double _dy = 0.65; // Normalized vertical position (0.0 to 1.0)
  bool _isRightSide = true;
  bool _isInteracting = false;
  bool _isReloading = false;
  bool _isExpanded = false;
  Timer? _dimTimer;
  double _opacity = 0.92;

  late final AnimationController _bloomController;
  late final Animation<double> _bloomAnimation;

  @override
  void initState() {
    super.initState();
    _bloomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _bloomAnimation = CurvedAnimation(
      parent: _bloomController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
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
    _bloomController.dispose();
    super.dispose();
  }

  void _resetDimTimer() {
    _dimTimer?.cancel();
    if (_opacity < 0.85) {
      setState(() => _opacity = 0.92);
    }
    _dimTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isInteracting && !_isExpanded) {
        setState(() => _opacity = 0.20);
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
    _bloomController.forward(from: 0.0);
  }

  void _collapse({VoidCallback? onCompleted}) {
    _bloomController.reverse().then((_) {
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
      Future.delayed(const Duration(milliseconds: 500), () {
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
    final topPadding = mq.padding.top + 50;
    final bottomPadding = mq.padding.bottom + 60;
    final availableH = (screenH - topPadding - bottomPadding).clamp(100.0, screenH);

    final currentY = topPadding + (_dy * availableH).clamp(0.0, availableH);

    if (_isExpanded) {
      return Positioned.fill(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Backdrop scrim that dismisses on outside tap
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _collapse(),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ),
            ),

            // Active blooming dial and satellites
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
    const totalBoxW = _orbitRadius + _satelliteSize + 20;
    const totalBoxH = (_orbitRadius * 2) + _satelliteSize + 20;

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        width: totalBoxW,
        height: totalBoxH,
        child: Stack(
          alignment: _isRightSide ? Alignment.centerRight : Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            // Blooming satellites & dotted orbit tracks
            if (_isExpanded)
              AnimatedBuilder(
                animation: _bloomAnimation,
                builder: (context, child) {
                  return _buildSatellitesAndOrbits(totalBoxW, totalBoxH);
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
              child: _buildQuadrantBezel(),
            ),
          ],
        ),
      ),
    );
  }

  /// The quarter-circle / 25% radial bezel docked on the screen edge
  /// Featuring dual concentric neon cyan arcs and a glossy glass highlight
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

    final innerRadius = _isRightSide
        ? const BorderRadius.only(
            topLeft: Radius.circular(_quadrantRadius - 6),
            bottomLeft: Radius.circular(_quadrantRadius - 6),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(_quadrantRadius - 6),
            bottomRight: Radius.circular(_quadrantRadius - 6),
          );

    return Container(
      width: _quadrantRadius,
      height: _quadrantHeight,
      decoration: BoxDecoration(
        color: const Color(0xF2090C14),
        borderRadius: outerRadius,
        border: Border.all(
          color: _isReloading
              ? AppTheme.cyan
              : (_isExpanded
                  ? AppTheme.cyan
                  : AppTheme.cyan.withValues(alpha: 0.65)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 14,
            offset: Offset(_isRightSide ? -3 : 3, 3),
          ),
          BoxShadow(
            color: AppTheme.cyan.withValues(alpha: _isExpanded || _isReloading ? 0.45 : 0.22),
            blurRadius: 18,
            spreadRadius: 1.5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle diagonal glass reflection
          Positioned.fill(
            child: ClipRRect(
              borderRadius: outerRadius,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Inner concentric cyan neon arc
          Positioned(
            right: _isRightSide ? 0 : null,
            left: !_isRightSide ? 0 : null,
            top: 6,
            bottom: 6,
            child: Container(
              width: _quadrantRadius - 6,
              decoration: BoxDecoration(
                borderRadius: innerRadius,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.cyan.withValues(alpha: _isExpanded ? 0.9 : 0.5),
                    width: 1.2,
                  ),
                  bottom: BorderSide(
                    color: AppTheme.cyan.withValues(alpha: _isExpanded ? 0.9 : 0.5),
                    width: 1.2,
                  ),
                  left: _isRightSide
                      ? BorderSide(
                          color: AppTheme.cyan.withValues(alpha: _isExpanded ? 0.9 : 0.5),
                          width: 1.2,
                        )
                      : BorderSide.none,
                  right: !_isRightSide
                      ? BorderSide(
                          color: AppTheme.cyan.withValues(alpha: _isExpanded ? 0.9 : 0.5),
                          width: 1.2,
                        )
                      : BorderSide.none,
                ),
              ),
            ),
          ),

          // Central telemetry & micro-indicator
          Center(
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
                    size: 15,
                    color: _isReloading
                        ? AppTheme.cyan
                        : (_isExpanded ? Colors.white : AppTheme.cyan),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Satellites blooming along the radial trajectory with background orbit arcs
  Widget _buildSatellitesAndOrbits(double totalW, double totalH) {
    final progress = _bloomAnimation.value;
    final angleRad = _orbitAngleDeg * math.pi / 180;

    final cosVal = math.cos(angleRad) * progress;
    final sinVal = math.sin(angleRad) * progress;

    // Anchor center on the screen bezel edge
    final anchorX = _isRightSide ? totalW : 0.0;
    final anchorY = totalH / 2;

    // Satellite centers
    final double reloadCenterX = anchorX + (_isRightSide ? -1 : 1) * _orbitRadius * cosVal;
    final double reloadCenterY = anchorY - _orbitRadius * sinVal;

    final double menuCenterX = anchorX + (_isRightSide ? -1 : 1) * _orbitRadius * cosVal;
    final double menuCenterY = anchorY + _orbitRadius * sinVal;

    final double halfSat = _satelliteSize / 2;

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cyber dotted trajectory guide tracks
          CustomPaint(
            size: Size(totalW, totalH),
            painter: _CyberOrbitTrackPainter(
              isRightSide: _isRightSide,
              progress: progress,
              orbitRadius: _orbitRadius,
              angleRad: angleRad,
            ),
          ),

          // 1. Top Satellite: Hot Reload (⚡)
          Positioned(
            left: reloadCenterX - halfSat,
            top: reloadCenterY - halfSat,
            child: Transform.scale(
              scale: progress.clamp(0.0, 1.0),
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

          // 2. Bottom Satellite: Dev Menu (🎛️)
          Positioned(
            left: menuCenterX - halfSat,
            top: menuCenterY - halfSat,
            child: Transform.scale(
              scale: progress.clamp(0.0, 1.0),
              child: _buildSatelliteButton(
                key: const Key('capsule_satellite_menu'),
                icon: PhosphorIconsRegular.slidersHorizontal,
                iconColor: AppTheme.cyan,
                tooltip: 'Dev Menu',
                onTap: _triggerMenuFromSatellite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Satellite circular button with dual concentric neon rings and electric cyan glow
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
            color: const Color(0xF2090D15),
            border: Border.all(
              color: isPulsing
                  ? AppTheme.cyan
                  : AppTheme.cyan.withValues(alpha: 0.75),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: AppTheme.cyan.withValues(alpha: isPulsing ? 0.65 : 0.35),
                blurRadius: isPulsing ? 20 : 12,
                spreadRadius: isPulsing ? 2.5 : 1,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Inner concentric ring for that high-tech HUD look
              Container(
                width: _satelliteSize - 10,
                height: _satelliteSize - 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xF50D121B),
                  border: Border.all(
                    color: AppTheme.cyan.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                ),
              ),

              // Glowing Icon
              Icon(
                icon,
                size: 22,
                color: iconColor,
                shadows: [
                  Shadow(
                    color: AppTheme.cyan.withValues(alpha: 0.8),
                    blurRadius: 8,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter that renders the subtle cyber-cyan dotted orbital guide tracks
/// connecting the quadrant to the blooming satellite action circles.
class _CyberOrbitTrackPainter extends CustomPainter {
  final bool isRightSide;
  final double progress;
  final double orbitRadius;
  final double angleRad;

  _CyberOrbitTrackPainter({
    required this.isRightSide,
    required this.progress,
    required this.orbitRadius,
    required this.angleRad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.05) return;

    final originX = isRightSide ? size.width : 0.0;
    final originY = size.height / 2;
    final center = Offset(originX, originY);

    final currentRadius = orbitRadius * progress;

    // 1. Faint outer secondary concentric ring
    final outerRingPaint = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.10 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final outerRect = Rect.fromCircle(
      center: center,
      radius: currentRadius + 18,
    );
    final startAngle = isRightSide ? (math.pi - angleRad - 0.28) : (-angleRad - 0.28);
    final sweepAngle = (angleRad * 2) + 0.56;
    canvas.drawArc(outerRect, startAngle, sweepAngle, false, outerRingPaint);

    // 2. Primary dotted trajectory arc passing right through the satellites
    final dotPaint = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.45 * progress)
      ..style = PaintingStyle.fill;

    const int dotCount = 28;
    for (int i = 0; i <= dotCount; i++) {
      final t = i / dotCount;
      final angle = startAngle + (sweepAngle * t);
      final dx = originX + currentRadius * math.cos(angle);
      final dy = originY + currentRadius * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 1.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CyberOrbitTrackPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRightSide != isRightSide;
  }
}
