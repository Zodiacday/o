import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class PresetsTab extends StatelessWidget {
  final VoidCallback onPasteClipboard;
  final VoidCallback onOpenManualModal;

  const PresetsTab({
    super.key,
    required this.onPasteClipboard,
    required this.onOpenManualModal,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
      children: [
        Text(
          'Quick Connect',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ).animate().fadeIn(duration: 250.ms),
        const SizedBox(height: 6),
        Text(
          'Connect to local development servers and tunnels',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
        ).animate().fadeIn(delay: 60.ms, duration: 250.ms),
        const SizedBox(height: 20),

        // Clipboard Connect Card
        Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF1E2638),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.clipboard_copy,
                        size: 16,
                        color: Color(0xFF00E5FF),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Clipboard Launcher',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Bounceable(
                      scaleFactor: 0.98,
                      onTap: onPasteClipboard,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131A26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF263347),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.clipboard_paste,
                              size: 16,
                              color: Color(0xFF00E5FF),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Open From Clipboard',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontSize: 14,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: 120.ms, duration: 300.ms)
            .slideY(begin: 0.08, end: 0),
        const SizedBox(height: 16),

        // Port Presets Card
        Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF1E2638),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.radio,
                        size: 16,
                        color: Color(0xFF00E5FF),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Common Local Ports',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['8090', '8080', '8081', '3000', '5000', '8000']
                        .map((port) {
                          return Bounceable(
                            scaleFactor: 0.95,
                            onTap: onOpenManualModal,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF080B11),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF1E2638),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                'Port $port',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  color: const Color(0xFF00E5FF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(delay: 180.ms, duration: 300.ms)
            .slideY(begin: 0.08, end: 0),
      ],
    );
  }
}
