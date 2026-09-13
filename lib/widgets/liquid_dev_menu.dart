import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../theme/app_theme.dart';
import 'floating_ghost_capsule.dart';

/// Helper to generate the exact organic fluid path tethered to the sidebar puck.
/// Combines a clean squircle menu body with an analytical metaball tangent bridge to the bezel hub.
@visibleForTesting
class ResponsiveFluidPathBuilder {
  static const double cornerRadius = 28.0;

  static Path buildPath({
    required Size size,
    required double anchorY,
    required bool isRightSide,
  }) {
    final bodyW = (size.width * 0.78).clamp(280.0, 320.0);
    final bodyH = (size.height * 0.62).clamp(440.0, 500.0);

    final bodyLeft = (size.width - bodyW - 42.0).clamp(16.0, size.width * 0.16);
    final bodyRight = bodyLeft + bodyW;
    final anchorX = size.width;

    final minBodyTop = 56.0;
    final maxBodyTop = size.height - bodyH - 36.0;
    final idealBodyTop = anchorY - (bodyH * 0.45);
    final bodyTop = idealBodyTop.clamp(minBodyTop, maxBodyTop);
    final bodyBottom = bodyTop + bodyH;

    const hubRadius = FloatingGhostCapsule.quadrantRadius; // 44.0

    // Hub vertical bounds on the screen bezel edge
    final hubTop = anchorY - hubRadius;
    final hubBottom = anchorY + hubRadius;

    // Tether neck attachment points on bodyRight
    final neckTop = (anchorY - hubRadius - 12.0)
        .clamp(bodyTop + cornerRadius + 6.0, bodyBottom - cornerRadius - 52.0);
    final neckBottom = (anchorY + hubRadius + 12.0)
        .clamp(neckTop + 40.0, bodyBottom - cornerRadius - 6.0);

    final path = Path();

    // 1. Start at top of the bezel hub on the screen edge
    path.moveTo(anchorX, hubTop);

    // 2. Straight line down along the bezel edge interface
    path.lineTo(anchorX, hubBottom);

    // 3. Smooth concave metaball flare from hubBottom outward to bodyRight, neckBottom
    path.cubicTo(
      anchorX - (anchorX - bodyRight) * 0.45,
      hubBottom,
      bodyRight + (anchorX - bodyRight) * 0.08,
      neckBottom + (hubBottom - neckBottom).abs() * 0.35,
      bodyRight,
      neckBottom,
    );

    // 4. Downward along the right flank to the bottom-right rounded corner
    path.lineTo(bodyRight, bodyBottom - cornerRadius);

    // 5. Bottom-Right squircle corner
    path.arcToPoint(
      Offset(bodyRight - cornerRadius, bodyBottom),
      radius: const Radius.circular(cornerRadius),
    );

    // 6. Along the bottom edge
    path.lineTo(bodyLeft + cornerRadius, bodyBottom);

    // 7. Bottom-Left squircle corner
    path.arcToPoint(
      Offset(bodyLeft, bodyBottom - cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );

    // 8. Along the left flank
    path.lineTo(bodyLeft, bodyTop + cornerRadius);

    // 9. Top-Left squircle corner
    path.arcToPoint(
      Offset(bodyLeft + cornerRadius, bodyTop),
      radius: const Radius.circular(cornerRadius),
    );

    // 10. Along the top edge
    path.lineTo(bodyRight - cornerRadius, bodyTop);

    // 11. Top-Right squircle corner
    path.arcToPoint(
      Offset(bodyRight, bodyTop + cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );

    // 12. Downward along the right flank to neckTop
    path.lineTo(bodyRight, neckTop);

    // 13. Smooth concave metaball flare from neckTop back to hubTop on the screen edge
    path.cubicTo(
      bodyRight + (anchorX - bodyRight) * 0.08,
      neckTop - (neckTop - hubTop).abs() * 0.35,
      anchorX - (anchorX - bodyRight) * 0.45,
      hubTop,
      anchorX,
      hubTop,
    );

    path.close();

    // Symmetrically mirror when docked on the left bezel
    if (!isRightSide) {
      final matrix = Matrix4.translationValues(size.width, 0.0, 0.0)
        ..multiply(Matrix4.diagonal3Values(-1.0, 1.0, 1.0));
      return path.transform(matrix.storage);
    }

    return path;
  }

  static Rect getBodyRect({
    required Size size,
    required double anchorY,
    required bool isRightSide,
  }) {
    final bodyW = (size.width * 0.78).clamp(280.0, 320.0);
    final bodyH = (size.height * 0.62).clamp(440.0, 500.0);

    final minBodyTop = 56.0;
    final maxBodyTop = size.height - bodyH - 36.0;
    final idealBodyTop = anchorY - (bodyH * 0.45);
    final bodyTop = idealBodyTop.clamp(minBodyTop, maxBodyTop);

    if (isRightSide) {
      final bodyLeft = (size.width - bodyW - 42.0).clamp(16.0, size.width * 0.16);
      return Rect.fromLTWH(bodyLeft, bodyTop, bodyW, bodyH);
    } else {
      final bodyRight = size.width - (size.width - bodyW - 42.0).clamp(16.0, size.width * 0.16);
      final bodyLeft = bodyRight - bodyW;
      return Rect.fromLTWH(bodyLeft, bodyTop, bodyW, bodyH);
    }
  }
}

/// CustomClipper that clips child widgets to the responsive fluid shape.
class ResponsiveFluidMenuClipper extends CustomClipper<Path> {
  final double anchorY;
  final bool isRightSide;

  ResponsiveFluidMenuClipper({
    required this.anchorY,
    required this.isRightSide,
  });

  @override
  Path getClip(Size size) {
    return ResponsiveFluidPathBuilder.buildPath(
      size: size,
      anchorY: anchorY,
      isRightSide: isRightSide,
    );
  }

  @override
  bool shouldReclip(covariant ResponsiveFluidMenuClipper oldClipper) {
    return oldClipper.anchorY != anchorY || oldClipper.isRightSide != isRightSide;
  }
}

/// CustomPainter that strokes the fluid outline with an electric cyan neon glow.
class ResponsiveFluidMenuPainter extends CustomPainter {
  final double anchorY;
  final bool isRightSide;

  ResponsiveFluidMenuPainter({
    required this.anchorY,
    required this.isRightSide,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = ResponsiveFluidPathBuilder.buildPath(
      size: size,
      anchorY: anchorY,
      isRightSide: isRightSide,
    );

    // 1. Soft atmospheric outer glow pass
    final outerGlowPaint = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawPath(path, outerGlowPaint);

    // 2. Focused vibrant cyan mid-pass
    final midGlowPaint = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(path, midGlowPaint);

    // 3. Crisp, bright electric cyan hairline edge
    final linePaint = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // 4. Liquid-glass inner specular highlight along top shoulder
    final bodyRect = ResponsiveFluidPathBuilder.getBodyRect(
      size: size,
      anchorY: anchorY,
      isRightSide: isRightSide,
    );
    final highlightPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(bodyRect.center.dx, bodyRect.top),
        Offset(bodyRect.center.dx, bodyRect.top + 75),
        [
          Colors.white.withValues(alpha: 0.60),
          AppTheme.cyan.withValues(alpha: 0.20),
          Colors.transparent,
        ],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant ResponsiveFluidMenuPainter oldDelegate) {
    return oldDelegate.anchorY != anchorY || oldDelegate.isRightSide != isRightSide;
  }
}

/// Ambient floating liquid blobs layer inspired by React-Bits BlobCursor & metaball physics.
class AmbientLiquidBlobsLayer extends StatefulWidget {
  final Rect bodyRect;
  const AmbientLiquidBlobsLayer({super.key, required this.bodyRect});

  @override
  State<AmbientLiquidBlobsLayer> createState() => _AmbientLiquidBlobsLayerState();
}

class _AmbientLiquidBlobsLayerState extends State<AmbientLiquidBlobsLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: AmbientLiquidBlobsPainter(
            progress: _animController.value,
            bodyRect: widget.bodyRect,
          ),
        );
      },
    );
  }
}

class AmbientLiquidBlobsPainter extends CustomPainter {
  final double progress;
  final Rect bodyRect;

  AmbientLiquidBlobsPainter({
    required this.progress,
    required this.bodyRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * math.pi;
    final center = bodyRect.center;
    final w = bodyRect.width;
    final h = bodyRect.height;

    // Node 1: Electric Cyan Lead Blob (React-Bits fast node)
    final c1 = Offset(
      center.dx + (w * 0.22) * math.cos(t),
      center.dy - (h * 0.18) + (h * 0.12) * math.sin(t * 1.3),
    );
    final r1 = (w * 0.26).clamp(65.0, 95.0);
    _drawGooeyBlob(
      canvas,
      center: c1,
      radius: r1,
      color: AppTheme.cyan,
      peakAlpha: 0.32,
    );

    // Node 2: Sapphire Indigo Mid Blob (React-Bits slow node)
    final c2 = Offset(
      center.dx - (w * 0.20) * math.sin(t * 0.8),
      center.dy + (h * 0.18) + (h * 0.14) * math.cos(t * 0.9),
    );
    final r2 = (w * 0.34).clamp(85.0, 125.0);
    _drawGooeyBlob(
      canvas,
      center: c2,
      radius: r2,
      color: const Color(0xFF6366F1),
      peakAlpha: 0.26,
    );

    // Node 3: Radiant Magenta Accent Blob (React-Bits trailing node)
    final c3 = Offset(
      center.dx + (w * 0.16) * math.sin(t * 1.4 + 1.2),
      center.dy + (h * 0.04) + (h * 0.16) * math.cos(t * 1.1),
    );
    final r3 = (w * 0.22).clamp(50.0, 75.0);
    _drawGooeyBlob(
      canvas,
      center: c3,
      radius: r3,
      color: const Color(0xFFD946EF),
      peakAlpha: 0.22,
    );
  }

  void _drawGooeyBlob(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color color,
    required double peakAlpha,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: peakAlpha),
          color.withValues(alpha: peakAlpha * 0.45),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant AmbientLiquidBlobsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.bodyRect != bodyRect;
  }
}

/// Reusable full Liquid Dev Menu Overlay widget.
class LiquidDevMenuOverlay extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final double anchorY;
  final bool isRightSide;
  final String? title;
  final bool isCliConnected;
  final VoidCallback onHotReload;
  final VoidCallback onRestart;
  final VoidCallback onOpenViewportSwitcher;
  final VoidCallback onOpenTerminal;
  final int terminalLogCount;
  final VoidCallback onClearCache;
  final VoidCallback onExit;
  final String selectedDeviceName;
  final IconData selectedDeviceIcon;

  const LiquidDevMenuOverlay({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.anchorY,
    required this.isRightSide,
    this.title,
    this.isCliConnected = true,
    required this.onHotReload,
    required this.onRestart,
    required this.onOpenViewportSwitcher,
    required this.onOpenTerminal,
    this.terminalLogCount = 0,
    required this.onClearCache,
    required this.onExit,
    this.selectedDeviceName = 'Native Device',
    this.selectedDeviceIcon = PhosphorIconsRegular.deviceMobile,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;

    final bloomAlignment = isRightSide
        ? Alignment(1.0, ((anchorY / screenH) * 2.0 - 1.0).clamp(-1.0, 1.0))
        : Alignment(-1.0, ((anchorY / screenH) * 2.0 - 1.0).clamp(-1.0, 1.0));

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !isOpen,
        child: AnimatedOpacity(
          opacity: isOpen ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) {
              final path = ResponsiveFluidPathBuilder.buildPath(
                size: mq.size,
                anchorY: anchorY,
                isRightSide: isRightSide,
              );
              if (path.contains(details.localPosition)) return;
              onClose();
            },
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.60),
              child: AnimatedSlide(
                offset: isOpen
                    ? Offset.zero
                    : Offset(isRightSide ? 0.05 : -0.05, 0.0),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: AnimatedScale(
                  scale: isOpen ? 1.0 : 0.05,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  alignment: bloomAlignment,
                  child: _buildSculpture(context, mq.size),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSculpture(BuildContext context, Size size) {
    final bodyRect = ResponsiveFluidPathBuilder.getBodyRect(
      size: size,
      anchorY: anchorY,
      isRightSide: isRightSide,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Fluid outline with luminous electric cyan glow
        CustomPaint(
          size: size,
          painter: ResponsiveFluidMenuPainter(
            anchorY: anchorY,
            isRightSide: isRightSide,
          ),
        ),

        // 2. Celestial oil painting background clipped to the exact fluid shape
        ClipPath(
          clipper: ResponsiveFluidMenuClipper(
            anchorY: anchorY,
            isRightSide: isRightSide,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Celestial textured oil painting
              Image.asset(
                'assets/celestial_menu_bg.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),

              // Deep ambient obsidian vignette overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xD8080C14),
                      const Color(0xB8090E1A),
                      const Color(0xE8080C14),
                    ],
                  ),
                ),
              ),

              // Ambient living liquid blobs layer (BlobCursor in Flutter)
              AmbientLiquidBlobsLayer(bodyRect: bodyRect),
            ],
          ),
        ),

        // 3. Active Foreground Docking Hub physically bonded to the fluid neck
        Positioned(
          top: anchorY - FloatingGhostCapsule.quadrantRadius,
          right: isRightSide ? 0 : null,
          left: !isRightSide ? 0 : null,
          child: _buildDockingHub(),
        ),

        // 4. Interactive crisp bento content positioned inside the fluid body
        Positioned(
          left: bodyRect.left,
          top: bodyRect.top,
          width: bodyRect.width,
          height: bodyRect.height,
          child: GestureDetector(
            onTap: () {}, // Trap taps inside menu body
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: _buildBentoContent(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDockingHub() {
    const hubRadius = FloatingGhostCapsule.quadrantRadius;
    const hubHeight = FloatingGhostCapsule.quadrantHeight;

    final borderRadius = isRightSide
        ? const BorderRadius.only(
            topLeft: Radius.circular(hubRadius),
            bottomLeft: Radius.circular(hubRadius),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(hubRadius),
            bottomRight: Radius.circular(hubRadius),
          );

    return GestureDetector(
      key: const Key('active_fluid_docking_hub'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onClose();
      },
      child: Tooltip(
        message: 'Close Dev Menu',
        child: Container(
          width: hubRadius,
          height: hubHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF0B0E17),
            borderRadius: borderRadius,
            border: Border.all(
              color: AppTheme.cyan,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.70),
                blurRadius: 14,
                offset: Offset(isRightSide ? -3 : 3, 3),
              ),
              BoxShadow(
                color: AppTheme.cyan.withValues(alpha: 0.40),
                blurRadius: 14,
                spreadRadius: 1.0,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isRightSide
                  ? PhosphorIconsRegular.caretRight
                  : PhosphorIconsRegular.caretLeft,
              size: 20,
              color: AppTheme.cyan,
              shadows: [
                Shadow(
                  color: AppTheme.cyan.withValues(alpha: 0.85),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. PreviewPort Header with official branding & close icon
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'assets/previewport-logo-transparent.png',
                                height: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'PreviewPort',
                                style: AppTypography.displayHero(
                                  color: Colors.white,
                                ).copyWith(fontSize: 18, letterSpacing: -0.2),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: onClose,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  PhosphorIconsRegular.x,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title ?? 'Flutter App',
                              style: AppTypography.subtitle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCliConnected
                                  ? const Color(0x2400F2FE)
                                  : const Color(0x18FFFFFF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCliConnected
                                    ? AppTheme.cyan.withValues(alpha: 0.50)
                                    : Colors.white24,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isCliConnected ? AppTheme.cyan : AppTheme.warning,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      if (isCliConnected)
                                        BoxShadow(
                                          color: AppTheme.cyan.withValues(alpha: 0.9),
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isCliConnected ? 'CLI SYNCED' : 'STANDALONE',
                                  style: AppTypography.monoData(
                                    color: isCliConnected ? AppTheme.cyan : Colors.white70,
                                    fontSize: 9,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 2. Dual Tactile Hero Action Pills (Hot Reload & Restart)
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onHotReload,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0x2200F2FE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.cyan.withValues(alpha: 0.95),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.cyan.withValues(alpha: 0.30),
                                    blurRadius: 12,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    PhosphorIconsRegular.arrowClockwise,
                                    size: 16,
                                    color: AppTheme.cyan,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'HOT RELOAD',
                                    style: AppTypography.button(
                                      fontSize: 11.5,
                                      color: AppTheme.cyan,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onRestart,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0x33101520),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    PhosphorIconsRegular.arrowsClockwise,
                                    size: 15,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'RESTART',
                                    style: AppTypography.button(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 3. Viewport Switcher Card
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onOpenViewportSwitcher,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0x33101520),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.cyan.withValues(alpha: 0.40),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selectedDeviceIcon,
                              size: 18,
                              color: AppTheme.cyan,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'VIEWPORT SWITCHER',
                                    style: AppTypography.sectionHud(
                                      color: AppTheme.textSecondary,
                                    ).copyWith(fontSize: 9.5),
                                  ),
                                  Text(
                                    selectedDeviceName,
                                    style: AppTypography.itemTitle(
                                      fontSize: 13.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              PhosphorIconsRegular.caretDown,
                              size: 14,
                              color: AppTheme.cyan,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 4. Compact Logs & Cache Row
                  Row(
                    children: [
                      // Logs Card
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onOpenTerminal,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0x33101520),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    PhosphorIconsRegular.terminalWindow,
                                    size: 17,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      'Logs',
                                      style: AppTypography.button(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: terminalLogCount > 0
                                          ? const Color(0x2A00F2FE)
                                          : const Color(0x18FFFFFF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$terminalLogCount',
                                      style: AppTypography.monoData(
                                        color: terminalLogCount > 0
                                            ? AppTheme.cyan
                                            : AppTheme.textMuted,
                                        fontSize: 9.5,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Clear Cache Card
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onClearCache,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0x33101520),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    PhosphorIconsRegular.trash,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Clear Cache',
                                    style: AppTypography.button(
                                      fontSize: 11.5,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 5. Exit to Scanner Footer
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onExit,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0x18FF4D4D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0x44FF4D4D),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              PhosphorIconsRegular.qrCode,
                              size: 15,
                              color: AppTheme.danger,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'EXIT TO SCANNER',
                              style: AppTypography.button(
                                fontSize: 11,
                                color: AppTheme.danger,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
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
