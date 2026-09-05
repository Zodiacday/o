import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:toastification/toastification.dart';
import 'qr_viewfinder_target.dart';
import 'network_status_pill.dart';

class HeroScanCard extends StatelessWidget {
  final VoidCallback onTap;

  const HeroScanCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Terminal CLI Command Prompt Chip (Above Wi-Fi Ready)
          Bounceable(
            scaleFactor: 0.96,
            onTap: () {
              Clipboard.setData(const ClipboardData(text: 'previewport'));
              HapticFeedback.lightImpact();
              toastification.show(
                context: context,
                type: ToastificationType.success,
                style: ToastificationStyle.flat,
                title: Text(
                  'Command Copied',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                description: Text(
                  "Run 'previewport' in your Flutter project root",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
                alignment: Alignment.topCenter,
                autoCloseDuration: const Duration(seconds: 2),
                primaryColor: const Color(0xFF00E5FF),
                backgroundColor: const Color(0xFF0D1117),
                foregroundColor: Colors.white,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF080B11),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1E2638),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.terminal,
                    size: 13,
                    color: Color(0xFF00E5FF),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '\$ ',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        TextSpan(
                          text: 'previewport',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 1,
                    height: 12,
                    color: const Color(0xFF1E2638),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.copy,
                        size: 11,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Run in project root to generate QR',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),

          const SizedBox(height: 12),

          // 2. Live Dynamic Network Sensing Pill
          const NetworkStatusPill(),

          const SizedBox(height: 16),

          // 3. Interactive Tactical Target Reticle (Option A)
          Bounceable(
            scaleFactor: 0.96,
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: QrViewfinderTarget(
              size: 210,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Centered solid vibrant electric cyan lens button
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E5FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.scan,
                      size: 26,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Crisp tracking text
                  Text(
                    'TAP TO SCAN',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
