import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/preview_diagnostic.dart';
import '../theme/app_theme.dart';

class PreviewErrorSheet extends StatelessWidget {
  final PreviewDiagnostic diagnostic;
  final VoidCallback onRetry;
  final VoidCallback onCopyDetails;
  final VoidCallback onDismiss;

  const PreviewErrorSheet({
    super.key,
    required this.diagnostic,
    required this.onRetry,
    required this.onCopyDetails,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final location = diagnostic.location;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, offset, child) {
        return Transform.translate(
          offset: Offset(0, MediaQuery.sizeOf(context).height * offset),
          child: child,
        );
      },
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.58,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                decoration: const BoxDecoration(
                  color: Color(0xF20A0A0A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: AppTheme.danger, width: 1.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 28,
                      offset: Offset(0, -10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.textMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppTheme.danger,
                            size: 21,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Preview failed',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _StageChip(label: diagnostic.stageLabel),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        diagnostic.message,
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 9),
                        Text(
                          location,
                          style: GoogleFonts.jetBrainsMono(
                            color: AppTheme.lightBlue,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (diagnostic.codeFrame != null &&
                          diagnostic.codeFrame!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 150),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              diagnostic.codeFrame!,
                              style: GoogleFonts.jetBrainsMono(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: onRetry,
                            icon: const Icon(Icons.refresh_rounded, size: 17),
                            label: const Text('Retry'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.cyan,
                              foregroundColor: Colors.black,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: onCopyDetails,
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copy details'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary,
                              side: const BorderSide(color: AppTheme.border),
                            ),
                          ),
                          TextButton(
                            onPressed: onDismiss,
                            child: const Text('Dismiss'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  final String label;

  const _StageChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: AppTheme.danger,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
