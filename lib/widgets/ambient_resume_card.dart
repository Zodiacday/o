import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/nearby_preview.dart';
import '../theme/app_theme.dart';

class AmbientResumeCard extends StatelessWidget {
  final NearbyPreview preview;
  final VoidCallback onResume;
  final VoidCallback? onScanQr;
  final bool animatePulse;

  const AmbientResumeCard({
    super.key,
    required this.preview,
    required this.onResume,
    this.onScanQr,
    this.animatePulse = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            animatePulse
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.statusGreen,
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.3, 1.3),
                        duration: 800.ms,
                      )
                : Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.statusGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
            const SizedBox(width: 8),
            Text(
              'LIVE WORKSTATION SENSED',
              style: AppTypography.sectionHud(color: AppTheme.cyan),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Bounceable(
          scaleFactor: 0.98,
          onTap: () {
            HapticFeedback.mediumImpact();
            onResume();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF090D16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.cyan.withValues(alpha: 0.35),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cyan.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.desktop,
                    color: AppTheme.cyan,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview.projectName,
                        style: AppTypography.itemTitle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${preview.displayEndpoint} · Ready on Wi-Fi',
                        style: AppTypography.monoData(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cyan,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        PhosphorIconsRegular.lightning,
                        color: Colors.black,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to Resume Preview',
                        style: AppTypography.button(
                          color: Colors.black,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onScanQr != null) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onScanQr!();
              },
              icon: const Icon(
                PhosphorIconsRegular.qrCode,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              label: Text(
                'Or scan a different QR code',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
