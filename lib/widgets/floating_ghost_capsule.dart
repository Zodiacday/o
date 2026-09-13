import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

part 'floating_ghost_capsule_painter.dart';
part 'floating_ghost_capsule_sections.dart';

/// An edge-docked developer control system featuring a 25% radial bezel dial
/// and two satellite action buttons (🔄 Hot Reload and 🛠️ Dev Menu).
///
/// Built with solid obsidian materials, single continuous luminous cyan arc line,
/// and a physics-driven morphing animation on open and close.
class FloatingGhostCapsule extends StatefulWidget {
  static const double quadrantRadius = 44.0;
  static const double quadrantHeight = 88.0;
  static const double orbitRadius = 92.0;
  static const double edgeClearance = 16.0;

  /// Single authoritative source of truth for the vertical center coordinate of the bezel hub.
  static double calculateCenterY({
    required double screenH,
    required double topInset,
    required double bottomInset,
    required double dy,
  }) {
    final topPadding = topInset + orbitRadius + edgeClearance;
    final bottomPadding = bottomInset + orbitRadius + edgeClearance;
    final availableH = (screenH - topPadding - bottomPadding).clamp(
      100.0,
      screenH,
    );
    return topPadding + (dy * availableH).clamp(0.0, availableH);
  }

  final VoidCallback onHotReload;
  final VoidCallback onOpenMenu;
  final VoidCallback? onOpenTerminal;
  final VoidCallback? onAnnotateBug;
  final void Function(double dy, bool isRightSide, double pixelY)? onPositionChanged;
  final bool isCliConnected;
  final bool isMenuOpen;

  const FloatingGhostCapsule({
    super.key,
    required this.onHotReload,
    required this.onOpenMenu,
    this.onOpenTerminal,
    this.onAnnotateBug,
    this.onPositionChanged,
    this.isCliConnected = true,
    this.isMenuOpen = false,
  });

  @override
  State<FloatingGhostCapsule> createState() => _FloatingGhostCapsuleState();
}

class _FloatingGhostCapsuleState extends State<FloatingGhostCapsule>
    with SingleTickerProviderStateMixin {
  static const _dyPrefKey = 'previewport_capsule_dy';
  static const _sidePrefKey = 'previewport_capsule_is_right';

  static const double _quadrantRadius = FloatingGhostCapsule.quadrantRadius;
  static const double _quadrantHeight = FloatingGhostCapsule.quadrantHeight;
  static const double _satelliteSize = 46.0;
  static const double _orbitRadius = 92.0;
  static const double _orbitAngleDeg = 38.0;

  static const double _totalBoxW = _orbitRadius + _satelliteSize + 16.0;
  static const double _totalBoxH = (_orbitRadius * 2) + _satelliteSize + 16.0;

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

    _hubRecoilAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(
              begin: 1.0,
              end: 0.92,
            ).chain(CurveTween(curve: Curves.easeOut)),
            weight: 35,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: 0.92,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeInBack)),
            weight: 65,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _morphController,
            curve: const Interval(0.0, 0.45, curve: Curves.linear),
          ),
        );

    _resetDimTimer();
    _loadSavedPosition();
  }

  double _calculateCurrentY() {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return 400.0;
    return FloatingGhostCapsule.calculateCenterY(
      screenH: mq.size.height,
      topInset: mq.padding.top,
      bottomInset: mq.padding.bottom,
      dy: _dy,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pixelY = _calculateCurrentY();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onPositionChanged?.call(_dy, _isRightSide, pixelY);
      }
    });
  }

  @override
  void didUpdateWidget(covariant FloatingGhostCapsule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMenuOpen && !widget.isMenuOpen) {
      if (mounted && _isExpanded) {
        _collapse();
      }
    }
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
        final pixelY = _calculateCurrentY();
        widget.onPositionChanged?.call(_dy, _isRightSide, pixelY);
      }
    } catch (_) {}
  }

  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_dyPrefKey, _dy);
      await prefs.setBool(_sidePrefKey, _isRightSide);
      final pixelY = _calculateCurrentY();
      widget.onPositionChanged?.call(_dy, _isRightSide, pixelY);
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
    _collapse(
      onCompleted: () {
        Future.delayed(const Duration(milliseconds: 450), () {
          if (mounted) setState(() => _isReloading = false);
        });
      },
    );
  }

  void _triggerMenuFromSatellite() {
    HapticFeedback.lightImpact();
    widget.onOpenMenu();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;

    // Guaranteed clearance so arc line & satellites never clip offscreen
    final topPadding = mq.padding.top + _orbitRadius + 16.0;
    final bottomPadding = mq.padding.bottom + _orbitRadius + 16.0;
    final availableH = (screenH - topPadding - bottomPadding).clamp(
      100.0,
      screenH,
    );

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
                child: Container(color: Colors.black.withValues(alpha: 0.30)),
              ),
            ),

            // Active morphing dial and satellites
            Positioned(
              top: currentY - (_totalBoxH / 2),
              right: _isRightSide ? 0 : null,
              left: !_isRightSide ? 0 : null,
              child: _buildDialChassis(
                currentY,
                screenW,
                topPadding,
                availableH,
              ),
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
}

/// Custom painter that renders exactly ONE continuous, elegant arc line
/// connecting from screen bezel edge (top) through the satellites and hub
/// to the screen bezel edge (bottom), unrolling dynamically with morph progress.
