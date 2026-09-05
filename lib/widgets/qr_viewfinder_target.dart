import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ultra-Crisp Minimalist Chamfered Reticle Corners
/// Features pure 45-degree chamfered corner vector brackets with tip node lights and zero background glow.
class QrViewfinderTarget extends StatefulWidget {
  final double size;
  final bool isPressed;
  final Widget? child;

  const QrViewfinderTarget({
    super.key,
    this.size = 280.0,
    this.isPressed = false,
    this.child,
  });

  @override
  State<QrViewfinderTarget> createState() => _QrViewfinderTargetState();
}

class _QrViewfinderTargetState extends State<QrViewfinderTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CrispChamferedCornersPainter(
            animationValue: _controller.value,
            isPressed: widget.isPressed,
          ),
          child: widget.child != null
              ? SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Center(child: widget.child),
                )
              : null,
        );
      },
    );
  }
}

class _CrispChamferedCornersPainter extends CustomPainter {
  final double animationValue;
  final bool isPressed;

  _CrispChamferedCornersPainter({
    required this.animationValue,
    required this.isPressed,
  });

  static const Color cyan = Color(0xFF00E5FF);
  static const Color skyBlue = Color(0xFF38BDF8);
  static const Color electricWhite = Color(0xFFE0F7FF);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Dynamic breathing scale for pure corners
    final pulseScale = 0.98 + 0.04 * math.sin(animationValue * math.pi);
    final boxSize = size.width * (isPressed ? 0.94 : pulseScale * 0.88);
    final rect = Rect.fromCenter(
      center: center,
      width: boxSize,
      height: boxSize,
    );

    // Corner Geometry Parameters (scales proportionally with size)
    final armLength = size.width * 0.15;
    final chamfer = size.width * 0.045; // 45-degree chamfered corner facet
    final strokeWidth = (size.width * 0.011).clamp(2.2, 3.2);

    // Glowing Shader Gradient along the vector lines
    final primaryShader = SweepGradient(
      center: Alignment.center,
      transform: GradientRotation(animationValue * 2 * math.pi),
      colors: const [cyan, skyBlue, electricWhite, skyBlue, cyan],
    ).createShader(rect);

    final outerStrokePaint = Paint()
      ..shader = primaryShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;

    final dotCore = Paint()..color = Colors.white;

    // Draw the 4 Crisp Chamfered Vector Corners with NO inner glow
    _drawCrispCorner(
      canvas,
      rect.topLeft,
      1,
      1,
      armLength,
      chamfer,
      outerStrokePaint,
      dotCore,
    );
    _drawCrispCorner(
      canvas,
      rect.topRight,
      -1,
      1,
      armLength,
      chamfer,
      outerStrokePaint,
      dotCore,
    );
    _drawCrispCorner(
      canvas,
      rect.bottomLeft,
      1,
      -1,
      armLength,
      chamfer,
      outerStrokePaint,
      dotCore,
    );
    _drawCrispCorner(
      canvas,
      rect.bottomRight,
      -1,
      -1,
      armLength,
      chamfer,
      outerStrokePaint,
      dotCore,
    );
  }

  /// Draws a crisp 45-degree chamfered corner bracket with zero inner glow
  void _drawCrispCorner(
    Canvas canvas,
    Offset corner,
    double dx,
    double dy,
    double arm,
    double chamfer,
    Paint strokePaint,
    Paint dotCore,
  ) {
    // Chamfered Corner Polygon Path
    final pHorizontalEnd = Offset(corner.dx + dx * arm, corner.dy);
    final pHorizontalChamfer = Offset(corner.dx + dx * chamfer, corner.dy);
    final pVerticalChamfer = Offset(corner.dx, corner.dy + dy * chamfer);
    final pVerticalEnd = Offset(corner.dx, corner.dy + dy * arm);

    // Main Chamfered Bracket Path
    final mainPath = Path()
      ..moveTo(pHorizontalEnd.dx, pHorizontalEnd.dy)
      ..lineTo(pHorizontalChamfer.dx, pHorizontalChamfer.dy)
      ..lineTo(pVerticalChamfer.dx, pVerticalChamfer.dy)
      ..lineTo(pVerticalEnd.dx, pVerticalEnd.dy);

    canvas.drawPath(mainPath, strokePaint);

    // Precision Tip Nodes at Arm Endpoints
    canvas.drawCircle(pHorizontalEnd, 2.2, dotCore);
    canvas.drawCircle(pVerticalEnd, 2.2, dotCore);
  }

  @override
  bool shouldRepaint(covariant _CrispChamferedCornersPainter oldDelegate) =>
      true;
}
