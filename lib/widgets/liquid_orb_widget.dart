import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pure Native High-Performance 3D Liquid Glass Orb Widget
/// Renders 3D twisting particle ribbons, chromatic dispersion,
/// and breathing liquid harmonics directly on the Flutter canvas with 0 dependencies.
class LiquidOrbWidget extends StatefulWidget {
  final double size;
  final String state; // 'idle' | 'thinking'

  const LiquidOrbWidget({super.key, this.size = 300.0, this.state = 'idle'});

  @override
  State<LiquidOrbWidget> createState() => _LiquidOrbWidgetState();
}

class _LiquidOrbWidgetState extends State<LiquidOrbWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isThinking = widget.state == 'thinking';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _LiquidOrbPainter(
            animationValue: _controller.value,
            isThinking: isThinking,
          ),
        );
      },
    );
  }
}

class _LiquidOrbPainter extends CustomPainter {
  final double animationValue;
  final bool isThinking;

  _LiquidOrbPainter({required this.animationValue, required this.isThinking});

  // Spectral Color Palette
  static const Color colorA = Color(0xFF63F1FF); // Electric Cyan
  static const Color colorB = Color(0xFF4A9DFF); // Sapphire Blue
  static const Color colorC = Color(0xFF8566FF); // Deep Violet
  static const Color colorD = Color(0xFFF15DE1); // Neon Magenta
  static const Color highlightColor = Color(0xFFF5FBFF); // Pure Core Glint

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;
    final speedMultiplier = isThinking ? 2.8 : 1.0;
    final t = animationValue * 2 * math.pi * speedMultiplier;

    // 1. Ethereal Radial Ambient Halo (Exp Bloom)
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colorA.withValues(alpha: isThinking ? 0.35 : 0.22),
          colorB.withValues(alpha: isThinking ? 0.25 : 0.14),
          colorC.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.35));
    canvas.drawCircle(center, radius * 1.35, haloPaint);

    // 2. Glass Sphere Outer Shell (Physical Fresnel Rim & Inner Refraction)
    final glassShellPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = SweepGradient(
        transform: GradientRotation(t * 0.2),
        colors: const [colorA, colorB, colorC, colorD, colorA],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glassShellPaint);

    // Subtle Glass Shadow & Inner Glow
    final innerGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..shader = RadialGradient(
        colors: [Colors.transparent, colorA.withValues(alpha: 0.18)],
        stops: const [0.82, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - 4, innerGlowPaint);

    // 3. 3D Parametric Twisting Particle Ribbons (4 Layers)
    const ribbonCount = 4;
    const segments = 120;
    final ribbonFold = isThinking ? 0.85 : 0.60;
    final ribbonBreath = isThinking ? 0.22 : 0.12;

    // Pulse factor
    final pulse = 1.0 + ribbonBreath * math.sin(t * 1.4);

    for (int layer = 0; layer < ribbonCount; layer++) {
      final layerCenter = layer - (ribbonCount - 1) / 2.0;
      final rotY = t * 0.18 + layerCenter * 0.35;
      final rotX = -0.22 + math.sin(t * 0.25 + layer) * 0.28;

      final points = <Offset>[];
      final colors = <Color>[];

      for (int i = 0; i <= segments; i++) {
        final uCoord = i / segments;
        final theta = uCoord * 2 * math.pi;

        // Mathematical 3D Curve Formula
        final local = theta + layer * 0.15;
        final foldPhase = 2.0 * local + t * 0.48 * 0.72;
        final rVal =
            (0.42 + (0.085 + ribbonFold * 0.05) * math.cos(foldPhase)) *
            radius *
            pulse;
        final orbit =
            local +
            t * 0.48 * 0.13 +
            math.sin(local - t * 0.11 + layer) * ribbonFold * 0.13;
        final vertical =
            ((0.24 + ribbonFold * 0.09) * math.sin(foldPhase) +
                0.055 * math.sin(local * 3.0 - t * 0.22 + layer * 0.7)) *
            radius *
            pulse;

        var x3d = rVal * math.cos(orbit);
        var y3d = vertical;
        var z3d = rVal * math.sin(orbit);

        // 3D Rotations (Rotate Y then Rotate X)
        final cosY = math.cos(rotY);
        final sinY = math.sin(rotY);
        final xRot = x3d * cosY + z3d * sinY;
        final zRot = -x3d * sinY + z3d * cosY;

        final cosX = math.cos(rotX);
        final sinX = math.sin(rotX);
        final yFinal = y3d * cosX - zRot * sinX;
        final zFinal = y3d * sinX + zRot * cosX;

        // Perspective Projection
        final depthScale = 0.85 + (zFinal / radius) * 0.25;
        final screenX = center.dx + xRot * depthScale;
        final screenY = center.dy + yFinal * depthScale;

        // Color interpolation based on position and layer
        final colorPhase = (uCoord + layer * 0.25 + t * 0.05) % 1.0;
        final color = _getPaletteColor(colorPhase);

        points.add(Offset(screenX, screenY));
        colors.add(
          color.withValues(
            alpha: (0.45 + (zFinal / radius) * 0.45).clamp(0.1, 0.95),
          ),
        );
      }

      // Draw Ribbon Glow Stroke
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final col = colors[i];

        // Core line
        final linePaint = Paint()
          ..color = col
          ..strokeWidth = isThinking ? 3.5 : 2.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(p1, p2, linePaint);

        // Glowing bloom dots on key vertices
        if (i % 6 == 0) {
          final dotPaint = Paint()
            ..color = col.withValues(alpha: 0.7)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
          canvas.drawCircle(p1, isThinking ? 4.5 : 3.0, dotPaint);

          // Specular glint
          final glintPaint = Paint()
            ..color = highlightColor.withValues(alpha: 0.8);
          canvas.drawCircle(p1, 1.2, glintPaint);
        }
      }
    }

    // 4. Center Radiant Core Glint (Liquid Center)
    final coreCenter = Offset(
      center.dx + math.sin(t * 0.6) * 12,
      center.dy + math.cos(t * 0.5) * 8,
    );
    final coreGlintPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              highlightColor.withValues(alpha: isThinking ? 0.9 : 0.6),
              colorA.withValues(alpha: 0.4),
              Colors.transparent,
            ],
            stops: const [0.0, 0.35, 1.0],
          ).createShader(
            Rect.fromCircle(center: coreCenter, radius: radius * 0.35),
          );
    canvas.drawCircle(coreCenter, radius * 0.35, coreGlintPaint);

    // 5. Specular Top-Left Glass Reflection Crescent
    final specRect = Rect.fromCircle(
      center: Offset(center.dx - radius * 0.28, center.dy - radius * 0.28),
      radius: radius * 0.45,
    );
    final specPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(specRect);
    canvas.drawOval(specRect, specPaint);
  }

  Color _getPaletteColor(double value) {
    final v = (value * 4.0) % 4.0;
    if (v < 1.0) {
      return Color.lerp(colorA, colorB, v)!;
    } else if (v < 2.0) {
      return Color.lerp(colorB, colorC, v - 1.0)!;
    } else if (v < 3.0) {
      return Color.lerp(colorC, colorD, v - 2.0)!;
    } else {
      return Color.lerp(colorD, colorA, v - 3.0)!;
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidOrbPainter oldDelegate) => true;
}
