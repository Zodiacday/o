part of 'floating_ghost_capsule.dart';

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
