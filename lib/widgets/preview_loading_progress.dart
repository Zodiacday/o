import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PreviewLoadingProgress extends StatelessWidget {
  final int progress;

  const PreviewLoadingProgress({super.key, required this.progress});

  int get _clampedProgress => progress.clamp(0, 100);

  @override
  Widget build(BuildContext context) {
    final currentProgress = _clampedProgress;

    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Preview loading $currentProgress percent',
      child: Container(
        key: const ValueKey('preview-loading-progress'),
        width: 204,
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHover.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: AppTheme.statusGreen.withValues(alpha: 0.24),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.statusGreen.withValues(alpha: 0.08),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Preparing preview',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$currentProgress%',
                  style: const TextStyle(
                    color: AppTheme.statusGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 7,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.statusGreen.withValues(alpha: 0.12),
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: currentProgress / 100),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value,
                          child: child,
                        ),
                      );
                    },
                    child: DecoratedBox(
                      key: const ValueKey('preview-loading-fill'),
                      decoration: BoxDecoration(
                        color: AppTheme.statusGreen,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: const [
                          BoxShadow(color: AppTheme.statusGreen, blurRadius: 7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              currentProgress == 0 ? 'Connecting…' : 'Loading preview…',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }
}
