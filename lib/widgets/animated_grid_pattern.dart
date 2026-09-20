import 'dart:math' as math;
import 'package:flutter/material.dart';

/// FlutterFX-style AnimatedGridPattern with staggered pulsing cells and skew.
///
/// Draws angled cyber grid lines and randomly animating neon-slate tiles.
/// Extends drawing coordinates into negative Y so that the grid bleeds
/// seamlessly behind the iOS Dynamic Island, status bar, and notch.
class AnimatedGridPattern extends StatefulWidget {
  final List<List<int>> squares;
  final double gridSize;
  final double skewAngle;

  const AnimatedGridPattern({
    super.key,
    required this.squares,
    this.gridSize = 32,
    this.skewAngle = 15,
  });

  @override
  State<AnimatedGridPattern> createState() => _AnimatedGridPatternState();
}

class _AnimatedGridPatternState extends State<AnimatedGridPattern>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.squares.length,
      (index) {
        final controller = AnimationController(
          duration: Duration(milliseconds: 1600 + _random.nextInt(1200)),
          vsync: this,
        );

        Future.delayed(Duration(milliseconds: _random.nextInt(1000)), () {
          if (mounted) {
            controller.repeat(reverse: true);
          }
        });

        return controller;
      },
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.12, end: 0.88).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOutSine,
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Transform(
          transform: Matrix4.skewY(widget.skewAngle * math.pi / 180),
          alignment: Alignment.centerLeft,
          child: CustomPaint(
            size: Size(constraints.maxWidth * 1.5, constraints.maxHeight * 1.5),
            painter: _GridPatternPainter(
              squares: widget.squares,
              gridSize: widget.gridSize,
              animations: _animations,
            ),
          ),
        );
      },
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  final List<List<int>> squares;
  final double gridSize;
  final List<Animation<double>> animations;

  _GridPatternPainter({
    required this.squares,
    required this.gridSize,
    required this.animations,
  }) : super(repaint: Listenable.merge(animations));

  @override
  void paint(Canvas canvas, Size size) {
    // Hairline grid lines in dark precision slate
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF334155).withValues(alpha: 0.28)
      ..strokeWidth = 0.5;

    // Start painting above y=0 to ensure full bleed behind the status bar
    // even after skew transformation.
    final startY = -120.0;
    final endY = size.height * 1.4;
    final endX = size.width * 1.4;

    // Vertical grid lines
    for (double x = 0; x <= endX; x += gridSize) {
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, endY),
        gridPaint,
      );
    }

    // Horizontal grid lines
    for (double y = startY; y <= endY; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(endX, y),
        gridPaint,
      );
    }

    // Animated glowing tiles
    final fillPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < squares.length; i++) {
      final square = squares[i];
      final animValue = i < animations.length ? animations[i].value : 0.5;

      final Rect squareRect = Rect.fromLTWH(
        square[0] * gridSize,
        square[1] * gridSize + startY,
        gridSize - 1,
        gridSize - 1,
      );

      // Cyber slate / electric cyan pulse tint
      final isCyanAccent = (i % 5 == 0);
      final baseColor = isCyanAccent
          ? const Color(0xFF00E5FF).withValues(alpha: 0.24 * animValue)
          : const Color(0xFF94A3B8).withValues(alpha: 0.20 * animValue);

      fillPaint.color = baseColor;
      canvas.drawRect(squareRect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPatternPainter oldDelegate) => true;
}
