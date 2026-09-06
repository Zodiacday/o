import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A restrained adaptation of FlutterFX's AnimatedGrid.
///
/// The original effect reveals grid children with a staggered slide, fade, and
/// blur. Here the children are deliberately empty, low-contrast cells so the
/// effect gives the PreviewPort shell depth without competing with the scanner.
class AnimatedGridBackground extends StatelessWidget {
  final ScrollController? scrollController;
  final int columns;
  final int rows;
  final double spacing;
  final Duration staggerDuration;
  final Duration animationDuration;

  const AnimatedGridBackground({
    super.key,
    this.scrollController,
    this.columns = 6,
    this.rows = 12,
    this.spacing = 6,
    this.staggerDuration = const Duration(milliseconds: 45),
    this.animationDuration = const Duration(milliseconds: 650),
  });

  @override
  Widget build(BuildContext context) {
    final scrollListenable =
        scrollController ?? const AlwaysStoppedAnimation<double>(0);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: scrollListenable,
        builder: (context, child) {
          final scrollOffset = scrollController?.hasClients == true
              ? scrollController!.offset
              : 0.0;
          final parallaxOffset = (scrollOffset * 0.34).clamp(0.0, 180.0);

          return Transform.translate(
            offset: Offset(0, -parallaxOffset),
            child: Transform.scale(
              alignment: Alignment.topCenter,
              scaleY: 1.24,
              child: child,
            ),
          );
        },
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          // Start at the top so the brand lockup can float above the grid.
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 0.92,
          ),
          itemCount: columns * rows,
          itemBuilder: (context, index) {
            return _AnimatedGridCell(
              key: ValueKey('animated-grid-cell-$index'),
              delay: Duration(
                milliseconds: index * staggerDuration.inMilliseconds,
              ),
              duration: animationDuration,
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedGridCell extends StatefulWidget {
  final Duration delay;
  final Duration duration;

  const _AnimatedGridCell({
    super.key,
    required this.delay,
    required this.duration,
  });

  @override
  State<_AnimatedGridCell> createState() => _AnimatedGridCellState();
}

class _AnimatedGridCellState extends State<_AnimatedGridCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _slideAnimation = Tween<double>(
      begin: 28,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.68, curve: Curves.easeOut),
      ),
    );
    _blurAnimation = Tween<double>(begin: 7, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.32, 1, curve: Curves.easeOut),
      ),
    );

    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
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
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: _blurAnimation.value,
                sigmaY: _blurAnimation.value,
              ),
              child: child,
            ),
          ),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.cyan.withValues(alpha: 0.025),
              AppTheme.lightBlue.withValues(alpha: 0.008),
              Colors.transparent,
            ],
            stops: const [0, 0.38, 1],
          ),
          border: Border.all(
            color: AppTheme.cyan.withValues(alpha: 0.075),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cyan.withValues(alpha: 0.025),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 3),
            ),
          ],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
