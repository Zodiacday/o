import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/network_status_service.dart';
import '../theme/app_theme.dart';
import 'network_status_pill.dart';
import 'preview_motion.dart';

/// The intentionally quiet first page of PreviewPort.
///
/// The page has one job: get a developer from the terminal QR code to their
/// running Flutter preview. Everything else stays secondary and lightweight.
class HeroScanCard extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onPasteUrl;
  final VoidCallback onEnterUrl;
  final VoidCallback onCopyCommand;
  final bool isBusy;
  final NetworkStatusService? networkService;

  const HeroScanCard({
    super.key,
    required this.onTap,
    required this.onPasteUrl,
    required this.onEnterUrl,
    required this.onCopyCommand,
    this.isBusy = false,
    this.networkService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect to a Flutter preview',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.55,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'PreviewPort connection information',
              hint: 'Shows setup and network details',
              child: IconButton(
                onPressed: () => _showInfoSheet(context),
                tooltip: 'Connection information',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  LucideIcons.info,
                  size: 17,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        _buildScanSurface(),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTextAction(
              label: 'Paste URL',
              icon: LucideIcons.clipboard_paste,
              onTap: onPasteUrl,
            ),
            _buildActionDivider(),
            _buildTextAction(
              label: 'Enter URL',
              icon: LucideIcons.pencil,
              onTap: onEnterUrl,
            ),
          ],
        ),
        const SizedBox(height: 13),
        _buildCommandLink(),
        const SizedBox(height: 4),
        Center(child: NetworkStatusPill(service: networkService)),
      ],
    );
  }

  Widget _buildScanSurface() {
    return Semantics(
      button: true,
      label: isBusy ? 'Opening scanner' : 'Tap to scan QR code',
      hint: isBusy ? 'Please wait' : 'Opens the in-app QR scanner',
      enabled: !isBusy,
      child: Bounceable(
        scaleFactor: 0.98,
        onTap: isBusy
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap();
              },
        child: PreviewMotionBorder(
          borderRadius: BorderRadius.circular(20),
          enabled: !isBusy,
          child: Container(
            height: 164,
            decoration: BoxDecoration(
              color: isBusy ? AppTheme.previewSurfaceElevated : AppTheme.cyan,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.previewBorder.withValues(alpha: 0.72),
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isBusy
                    ? Column(
                        key: const ValueKey('busy'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 25,
                            height: 25,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.1,
                              color: AppTheme.cyan,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Opening scanner…',
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('ready'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PreviewBreathing(
                            child: Icon(
                              LucideIcons.scan_qr_code,
                              size: 30,
                              color: Colors.black.withValues(alpha: 0.82),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to scan QR code',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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

  Widget _buildTextAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      hint: 'Use a preview URL instead of scanning',
      child: Bounceable(
        scaleFactor: 0.96,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.cyan.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: AppTheme.cyan),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionDivider() {
    return Container(width: 1, height: 14, color: AppTheme.previewBorder);
  }

  Widget _buildCommandLink() {
    return Semantics(
      button: true,
      label: 'Copy previewport start command',
      hint: 'Copies the command to the clipboard',
      child: GestureDetector(
        key: const Key('copy-cli-command'),
        onTap: onCopyCommand,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Run ',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  TextSpan(
                    text: 'previewport start',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const TextSpan(text: '  '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      LucideIcons.copy,
                      size: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How PreviewPort connects',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Run this in your Flutter project root, then scan the QR code it prints.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: 'Copy previewport start command',
                hint: 'Copies the command to the clipboard',
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onCopyCommand();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.previewSurfaceElevated,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: AppTheme.previewBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.terminal,
                          size: 15,
                          color: AppTheme.cyan,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'previewport start',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(
                          LucideIcons.copy,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(child: NetworkStatusPill(service: networkService)),
            ],
          ),
        ),
      ),
    );
  }
}
