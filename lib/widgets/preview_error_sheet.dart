import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../models/preview_diagnostic.dart';
import '../theme/app_theme.dart';

/// Minimalist, Expo LogBox-style developer diagnostic interface.
/// Supports both a full IDE-grade code-frame modal and a collapsible
/// 48px compact bottom toast bar.
class PreviewErrorSheet extends StatefulWidget {
  final PreviewDiagnostic diagnostic;
  final VoidCallback onRetry;
  final VoidCallback onCopyDetails;
  final VoidCallback onDismiss;
  final bool initiallyExpanded;

  const PreviewErrorSheet({
    super.key,
    required this.diagnostic,
    required this.onRetry,
    required this.onCopyDetails,
    required this.onDismiss,
    this.initiallyExpanded = true,
  });

  @override
  State<PreviewErrorSheet> createState() => _PreviewErrorSheetState();
}

class _PreviewErrorSheetState extends State<PreviewErrorSheet> {
  late bool _isExpanded;
  bool _isCopied = false;

  Timer? _copiedTimer;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    super.dispose();
  }

  void _handleCopy() {
    _copiedTimer?.cancel();
    HapticFeedback.lightImpact();
    widget.onCopyDetails();
    setState(() => _isCopied = true);
    _copiedTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _isExpanded ? _buildFullLogBox(context) : _buildCompactToast(context),
    );
  }

  /// Compact Expo-style bottom toast bar (~48px)
  Widget _buildCompactToast(BuildContext context) {
    final location = widget.diagnostic.location;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('compact_toast'),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _isExpanded = true);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xF5161922),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.danger.withValues(alpha: 0.65),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Red error pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.diagnostic.stageLabel.toUpperCase(),
                        style: AppTypography.actionLabel(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Truncated error message & location
                    Expanded(
                      child: Text(
                        location.isNotEmpty
                            ? '$location — ${widget.diagnostic.message}'
                            : widget.diagnostic.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.monoData(
                          fontSize: 11.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Quick Reload button
                    InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onRetry();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              PhosphorIconsRegular.arrowClockwise,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Reload',
                              style: AppTypography.button(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Dismiss button
                    InkWell(
                      onTap: widget.onDismiss,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          PhosphorIconsRegular.x,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Full Expo LogBox modal sheet
  Widget _buildFullLogBox(BuildContext context) {
    final location = widget.diagnostic.location;
    final codeFrame = widget.diagnostic.codeFrame;
    final screenH = MediaQuery.sizeOf(context).height;

    return SafeArea(
      key: const ValueKey('full_logbox'),
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
                // Swipe down collapses to compact toast
                HapticFeedback.lightImpact();
                setState(() => _isExpanded = false);
              }
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenH * 0.76,
              ),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xF8141720),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  border: Border(
                    top: BorderSide(color: Color(0x33FFFFFF), width: 1.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black87,
                      blurRadius: 32,
                      offset: Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top drag bar & header controls
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 14, 6),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Red Error badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  widget.diagnostic.stageLabel,
                                  style: AppTypography.actionLabel(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Preview failed',
                                style: AppTypography.subtitle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              // Collapse to toast button
                              IconButton(
                                tooltip: 'Collapse to toast',
                                icon: const Icon(
                                  PhosphorIconsRegular.caretDown,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _isExpanded = false);
                                },
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                              ),
                              // Dismiss button
                              IconButton(
                                tooltip: 'Dismiss',
                                icon: const Icon(
                                  PhosphorIconsRegular.x,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                onPressed: widget.onDismiss,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Scrollable error details & code frame
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Error Message (Bold, prominent)
                            Text(
                              widget.diagnostic.message,
                              style: AppTypography.modalTitle(
                                color: Colors.white,
                              ),
                            ),

                            // File & Line Location
                            if (location.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                location,
                                style: AppTypography.monoData(
                                  fontSize: 12,
                                  color: const Color(0xFF8B949E),
                                ),
                              ),
                            ],

                            // Minimal IDE Code Frame
                            if (codeFrame != null && codeFrame.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              _buildCodeFrame(codeFrame),
                            ],
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // Bottom flat action toolbar
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                      decoration: const BoxDecoration(
                        color: Color(0xF80F1118),
                        border: Border(
                          top: BorderSide(color: Color(0x1FFFFFFF), width: 0.8),
                        ),
                      ),
                      child: Row(
                        children: [
                          // 1. Dismiss button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onDismiss,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.06),
                                foregroundColor: AppTheme.textPrimary,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Dismiss',
                                style: AppTypography.button(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 2. Copy details button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _handleCopy,
                              icon: Icon(
                                _isCopied
                                    ? PhosphorIconsRegular.check
                                    : PhosphorIconsRegular.copy,
                                size: 14,
                                color: _isCopied ? AppTheme.cyan : Colors.white,
                              ),
                              label: Text(
                                _isCopied ? 'Copied' : 'Copy details',
                                style: AppTypography.button(
                                  fontSize: 12,
                                  color: _isCopied ? AppTheme.cyan : Colors.white,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.06),
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: _isCopied
                                      ? AppTheme.cyan.withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.15),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 3. Retry / Reload button
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                widget.onRetry();
                              },
                              icon: const Icon(
                                PhosphorIconsRegular.arrowClockwise,
                                size: 14,
                                color: Colors.black,
                              ),
                              label: Text(
                                'Retry',
                                style: AppTypography.button(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.cyan,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Minimal IDE code frame with high contrast and line-number column
  Widget _buildCodeFrame(String rawCodeFrame) {
    final lines = rawCodeFrame.split('\n');

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0E14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x2BFFFFFF), width: 0.9),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines.map((line) {
                final isErrorLine = line.trimLeft().startsWith('>') ||
                    (widget.diagnostic.line != null && line.contains('${widget.diagnostic.line}'));

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isErrorLine
                        ? const Color(0x3D8B1D2C)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    line,
                    style: AppTypography.monoData(
                      fontSize: 11.5,
                      color: isErrorLine ? Colors.white : const Color(0xFFADB5BD),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
