import 'package:flutter/material.dart';

/// Detailed Glowing Cyan QR Matrix Vector Graphic matching Mockup 1
class GlowingQrMatrix extends StatelessWidget {
  final double size;

  const GlowingQrMatrix({super.key, this.size = 170.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: CustomPaint(painter: _DetailedQrPainter()),
    );
  }
}

class _DetailedQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cyanPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;

    final cyanStroke = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final bracketStroke = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const w = 170.0;
    const h = 170.0;

    // 1. Four Outer Corner Rounded Framing Brackets
    const bArm = 20.0;
    const bR = 12.0;

    // Top-Left Bracket
    final tl = Path()
      ..moveTo(4, 4 + bArm)
      ..lineTo(4, 4 + bR)
      ..arcToPoint(const Offset(4 + bR, 4), radius: const Radius.circular(bR))
      ..lineTo(4 + bArm, 4);
    canvas.drawPath(tl, bracketStroke);

    // Top-Right Bracket
    final tr = Path()
      ..moveTo(w - 4 - bArm, 4)
      ..lineTo(w - 4 - bR, 4)
      ..arcToPoint(Offset(w - 4, 4 + bR), radius: const Radius.circular(bR))
      ..lineTo(w - 4, 4 + bArm);
    canvas.drawPath(tr, bracketStroke);

    // Bottom-Left Bracket
    final bl = Path()
      ..moveTo(4, h - 4 - bArm)
      ..lineTo(4, h - 4 - bR)
      ..arcToPoint(Offset(4 + bR, h - 4), radius: const Radius.circular(bR))
      ..lineTo(4 + bArm, h - 4);
    canvas.drawPath(bl, bracketStroke);

    // Bottom-Right Bracket
    final br = Path()
      ..moveTo(w - 4 - bArm, h - 4)
      ..lineTo(w - 4 - bR, h - 4)
      ..arcToPoint(Offset(w - 4, h - 4 - bR), radius: const Radius.circular(bR))
      ..lineTo(w - 4, h - 4 - bArm);
    canvas.drawPath(br, bracketStroke);

    // 2. Three Corner Position Detection Squares
    void drawFinderPattern(double x, double y) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, 36, 36),
          const Radius.circular(8),
        ),
        cyanStroke,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 9, y + 9, 18, 18),
          const Radius.circular(4),
        ),
        cyanPaint,
      );
    }

    drawFinderPattern(22, 22); // Top-Left
    drawFinderPattern(w - 22 - 36, 22); // Top-Right
    drawFinderPattern(22, h - 22 - 36); // Bottom-Left

    // 3. Dense Glowing QR Data Grid Modules
    final modules = [
      // Top row bridges
      const Rect.fromLTWH(68, 24, 6, 6),
      const Rect.fromLTWH(80, 24, 6, 12),
      const Rect.fromLTWH(96, 24, 6, 6),
      const Rect.fromLTWH(68, 36, 18, 6),
      const Rect.fromLTWH(92, 36, 10, 6),
      const Rect.fromLTWH(74, 48, 6, 18),
      const Rect.fromLTWH(86, 48, 16, 6),

      // Center cluster
      const Rect.fromLTWH(68, 70, 8, 8),
      const Rect.fromLTWH(82, 68, 6, 14),
      const Rect.fromLTWH(94, 72, 8, 8),
      const Rect.fromLTWH(74, 86, 14, 6),
      const Rect.fromLTWH(92, 86, 10, 14),
      const Rect.fromLTWH(68, 98, 8, 14),
      const Rect.fromLTWH(82, 98, 6, 6),

      // Left column bridge
      const Rect.fromLTWH(24, 68, 6, 12),
      const Rect.fromLTWH(36, 74, 6, 6),
      const Rect.fromLTWH(48, 68, 6, 18),
      const Rect.fromLTWH(24, 88, 18, 6),
      const Rect.fromLTWH(48, 92, 6, 12),

      // Right column cluster
      const Rect.fromLTWH(w - 22 - 36, 68, 12, 6),
      const Rect.fromLTWH(w - 22 - 18, 68, 6, 18),
      const Rect.fromLTWH(w - 22 - 36, 80, 6, 12),
      const Rect.fromLTWH(w - 22 - 24, 84, 12, 6),
      const Rect.fromLTWH(w - 22 - 36, 98, 18, 6),
      const Rect.fromLTWH(w - 22 - 12, 96, 6, 14),

      // Bottom row bridges
      const Rect.fromLTWH(68, 118, 12, 6),
      const Rect.fromLTWH(86, 118, 6, 18),
      const Rect.fromLTWH(98, 118, 14, 6),
      const Rect.fromLTWH(74, 130, 8, 8),
      const Rect.fromLTWH(92, 130, 8, 8),
      const Rect.fromLTWH(w - 22 - 36, 118, 8, 8),
      const Rect.fromLTWH(w - 22 - 22, 122, 14, 6),
      const Rect.fromLTWH(w - 22 - 36, 134, 18, 6),
      const Rect.fromLTWH(w - 22 - 12, 134, 6, 14),
    ];

    for (final rect in modules) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        cyanPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
