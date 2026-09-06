import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small motion primitives adapted from the Border Beam / ripple techniques
/// explored in the MIT-licensed FlutterFX widget collection.
///
/// The motion is deliberately slower and quieter for PreviewPort: it should
/// establish focus, not compete with the live preview workflow.
class PreviewMotionBorder extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final Duration duration;
  final bool enabled;

  const PreviewMotionBorder({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.duration = const Duration(seconds: 8),
    this.enabled = true,
  });

  @override
  State<PreviewMotionBorder> createState() => _PreviewMotionBorderState();
}

class _PreviewMotionBorderState extends State<PreviewMotionBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant PreviewMotionBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _controller.repeat();
    } else if (!widget.enabled && oldWidget.enabled) {
      _controller.stop();
      _controller.value = 0;
    }
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
      builder: (context, child) {
        return CustomPaint(
          painter: _PreviewBorderPainter(
            progress: widget.enabled ? _controller.value : 0,
            borderRadius: widget.borderRadius,
            active: widget.enabled,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _PreviewBorderPainter extends CustomPainter {
  final double progress;
  final BorderRadius borderRadius;
  final bool active;

  const _PreviewBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect.deflate(0.7));
    final path = Path()..addRRect(rrect);

    final staticPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppTheme.previewBorder;
    canvas.drawPath(path, staticPaint);

    if (!active || size.width <= 0 || size.height <= 0) return;

    final metric = path.computeMetrics().first;
    final beamLength = metric.length * 0.18;
    final start = progress * metric.length;
    final end = start + beamLength;
    final beamPath =
        end <= metric.length ? metric.extractPath(start, end) : Path()
          ..addPath(metric.extractPath(start, metric.length), Offset.zero)
          ..addPath(metric.extractPath(0, end - metric.length), Offset.zero);

    final startPoint =
        metric.getTangentForOffset(start)?.position ?? Offset.zero;
    final endPoint =
        metric.getTangentForOffset(end % metric.length)?.position ??
        Offset.zero;
    final beamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        startPoint,
        endPoint,
        [
          AppTheme.cyan.withValues(alpha: 0.0),
          AppTheme.cyan.withValues(alpha: 0.88),
          AppTheme.lightBlue.withValues(alpha: 0.0),
        ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawPath(beamPath, beamPaint);
  }

  @override
  bool shouldRepaint(covariant _PreviewBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.active != active ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class PreviewBreathing extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Duration duration;
  final double minScale;

  const PreviewBreathing({
    super.key,
    required this.child,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 2200),
    this.minScale = 0.94,
  });

  @override
  State<PreviewBreathing> createState() => _PreviewBreathingState();
}

class _PreviewBreathingState extends State<PreviewBreathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant PreviewBreathing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && oldWidget.enabled) {
      _controller.stop();
      _controller.value = 1;
    }
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
      child: widget.child,
      builder: (context, child) {
        final value = widget.enabled
            ? Curves.easeInOut.transform(_controller.value)
            : 1.0;
        return Transform.scale(
          scale: widget.minScale + ((1 - widget.minScale) * value),
          child: child,
        );
      },
    );
  }
}
