import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The single loading surface shown while a Flutter preview is starting.
///
/// The progress arc is intentionally rendered without a background track. The
/// empty portion stays black so the loading state feels calm rather than like
/// a dashboard full of competing indicators.
class PreviewLoadingProgress extends StatefulWidget {
  final int progress;
  final String? projectName;

  const PreviewLoadingProgress({
    super.key,
    required this.progress,
    this.projectName,
  });

  @override
  State<PreviewLoadingProgress> createState() => _PreviewLoadingProgressState();
}

class _PreviewLoadingProgressState extends State<PreviewLoadingProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  bool _reduceMotion = false;
  bool _motionConfigured = false;

  int get _clampedProgress => widget.progress.clamp(0, 100).toInt();

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_motionConfigured && reduceMotion == _reduceMotion) return;

    _motionConfigured = true;
    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _shimmerController.stop();
    } else {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentProgress = _clampedProgress;
    final projectName = widget.projectName?.trim().isNotEmpty == true
        ? widget.projectName!.trim()
        : 'Flutter preview';

    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Loading Flutter preview $currentProgress percent',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : 390.0;
          final ringSize = math.min(248.0, math.max(0.0, width - 48));

          return Stack(
            key: const ValueKey('preview-loading-progress'),
            fit: StackFit.expand,
            children: [
              Positioned(
                top: math.max(20.0, MediaQuery.paddingOf(context).top + 16),
                left: 24,
                child: _buildBrand(),
              ),
              Align(
                alignment: const Alignment(0, -0.12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Opening preview',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.35,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _buildRing(size: ringSize, progress: currentProgress),
                      const SizedBox(height: 20),
                      Text(
                        projectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrand() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/previewport-logo-transparent.png',
          width: 25,
          height: 25,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        const Text(
          'PreviewPort',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildRing({required double size, required int progress}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: progress / 100),
      duration: _reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, _) {
        return AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, _) {
            return CustomPaint(
              key: const ValueKey('preview-loading-ring'),
              size: Size.square(size),
              painter: _ProgressRingPainter(
                progress: animatedProgress,
                shimmer: _shimmerController.value,
              ),
              child: SizedBox.square(
                dimension: size,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '$progress'),
                            const TextSpan(
                              text: '%',
                              style: TextStyle(fontSize: 23, letterSpacing: 0),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 38,
                          fontWeight: FontWeight.w300,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double shimmer;

  const _ProgressRingPainter({required this.progress, required this.shimmer});

  @override
  void paint(Canvas canvas, Size size) {
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    if (clampedProgress <= 0) return;

    const strokeWidth = 5.0;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    final sweepAngle = math.pi * 2 * clampedProgress;

    final glowPaint = Paint()
      ..color = AppTheme.statusGreen.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth + 4
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    final arcPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF15803D),
          AppTheme.statusGreen,
          Color(0xFF86EFAC),
          AppTheme.statusGreen,
        ],
        stops: [0.0, 0.42, 0.78, 1.0],
        startAngle: startAngle,
        endAngle: startAngle + math.pi * 2,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

    // A fine illuminated core gives the active stroke a rounded surface.
    final corePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xB3BBF7D0), Color(0x006BE89B)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;
    canvas.drawArc(rect, startAngle, sweepAngle, false, corePaint);

    final endpointAngle = startAngle + sweepAngle;
    final endpoint = Offset(
      center.dx + radius * math.cos(endpointAngle),
      center.dy + radius * math.sin(endpointAngle),
    );
    final shimmerPaint = Paint()
      ..color = const Color(0xFFBBF7D0).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    final shimmerPulse = 2.5 + math.sin(shimmer * math.pi * 2) * 0.7;
    canvas.drawCircle(endpoint, shimmerPulse, shimmerPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.shimmer != shimmer;
  }
}
