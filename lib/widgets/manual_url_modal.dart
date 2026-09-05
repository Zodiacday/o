import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../theme/app_theme.dart';

class ManualUrlModal extends StatefulWidget {
  final ValueChanged<String> onConnect;

  const ManualUrlModal({super.key, required this.onConnect});

  @override
  State<ManualUrlModal> createState() => _ManualUrlModalState();
}

class _ManualUrlModalState extends State<ManualUrlModal> {
  final _textController = TextEditingController(text: 'http://');

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: const Color(0xF8000000),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: const Color(0xFF1E2638),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manual Web Connect',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _textController,
                autofocus: true,
                keyboardType: TextInputType.url,
                style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFF00E5FF),
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'http://192.168.0.25:8090',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: const Color(0xFF000000),
                  prefixIcon: const Icon(
                    LucideIcons.link_2,
                    color: Color(0xFF00E5FF),
                    size: 16,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E2638)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E2638)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF00E5FF),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Port Presets with Bounceable
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [':8090', ':8080', ':8081', ':3000', ':5000'].map((
                  port,
                ) {
                  return Bounceable(
                    scaleFactor: 0.95,
                    onTap: () {
                      final current = _textController.text.trim();
                      if (!current.contains(':') ||
                          current.startsWith('http://') ||
                          current.startsWith('https://')) {
                        _textController.text = '$current$port';
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF080B11),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF1E2638),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        port,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: const Color(0xFF00E5FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Bounceable(
                  scaleFactor: 0.98,
                  onTap: () {
                    final url = _textController.text.trim();
                    if (url.startsWith('http://') ||
                        url.startsWith('https://')) {
                      Navigator.of(context).pop();
                      widget.onConnect(url);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF00E5FF,
                          ).withValues(alpha: 0.35),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Connect & Launch',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
