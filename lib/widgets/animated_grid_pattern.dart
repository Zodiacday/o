import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Exact implementation of AnimatedGridPattern from flutterfx/flutterfx_widgets
/// (lib/background-grid-blinker/background_grid_blinker.dart).
class AnimatedGridPattern extends StatefulWidget {
  final List<List<int>> squares;
  final double gridSize;
  final double skewAngle;

  const AnimatedGridPattern({
    super.key,
    required this.squares,
    this.gridSize = 40,
    this.skewAngle = 12,
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
    // Create controllers with staggered start times
    _controllers = List.generate(
      widget.squares.length,
      (index) {
        final controller = AnimationController(
          duration: Duration(milliseconds: 1500 + _random.nextInt(1000)),
          vsync: this,
        );

        // Add a delayed start for each controller
        Future.delayed(Duration(milliseconds: _random.nextInt(1000)), () {
          if (mounted) {
            controller.repeat(reverse: true);
          }
        });

        return controller;
      },
    );

    // Create animations with more dramatic opacity changes
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.1, end: 0.9).animate(
        CurvedAnimation(
          parent: controller,
          // Use a custom curve for more interesting blinking effect
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
          child: CustomPaint(
            size: Size(constraints.maxWidth * 1.4, constraints.maxHeight * 1.4),
            painter: GridPatternPainter(
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

class GridPatternPainter extends CustomPainter {
  final List<List<int>> squares;
  final double gridSize;
  final List<Animation<double>> animations;

  GridPatternPainter({
    required this.squares,
    required this.gridSize,
    required this.animations,
  }) : super(repaint: Listenable.merge(animations));

  @override
  void paint(Canvas canvas, Size size) {
    // Draw base grid with slightly darker lines
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x <= size.width * 1.8; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height * 1.5),
        gridPaint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height * 1.5; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Draw animated squares with a gradient effect
    final fillPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < squares.length; i++) {
      final square = squares[i];

      // Create a gradient for each square
      final Rect squareRect = Rect.fromLTWH(
        square[0] * gridSize,
        square[1] * gridSize,
        gridSize - 1,
        gridSize - 1,
      );

      fillPaint.color = Colors.grey.withValues(alpha: 0.3 * animations[i].value);

      canvas.drawRect(squareRect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
