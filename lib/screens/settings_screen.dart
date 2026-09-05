import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:toastification/toastification.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cache_management_modal.dart';
import '../widgets/history_management_modal.dart';
import 'licenses_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _sessionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadHistoryCount();
  }

  Future<void> _loadHistoryCount() async {
    final history = await HistoryService.getHistory();
    if (mounted) {
      setState(() => _sessionCount = history.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: 110,
          ),
          children: [
            // 1. Studio Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PREVIEWPORT STUDIO',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 1.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF1E2638),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'v1.0.0 · Web Engine',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF00E5FF),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              'Developer Settings',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 20),

            // 2. Data & Storage Section
            _buildSectionHeader('DATA & STORAGE'),
            const SizedBox(height: 8),
            _buildMachinedPanel([
              _buildTelemetryTile(
                icon: LucideIcons.hard_drive,
                title: 'Web Cache',
                subtitle: 'Scripts, temporary assets & cookies',
                telemetryTag: '3.8 MB',
                tagColor: const Color(0xFF00E5FF),
                onTap: () => CacheManagementModal.show(
                  context,
                  onCleared: () {
                    if (mounted) setState(() {});
                  },
                ),
              ),
              _buildInsetDivider(),
              _buildTelemetryTile(
                icon: LucideIcons.clock,
                title: 'Session History',
                subtitle: 'Saved local preview connections',
                telemetryTag: '$_sessionCount Scans',
                tagColor: const Color(0xFF94A3B8),
                onTap: () => HistoryManagementModal.show(
                  context,
                  onUpdated: () => _loadHistoryCount(),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // 3. Privacy & Security Section
            _buildSectionHeader('PRIVACY & SECURITY'),
            const SizedBox(height: 8),
            _buildMachinedPanel([
              _buildTelemetryTile(
                icon: LucideIcons.shield_check,
                title: 'Camera & Network',
                subtitle: 'On-device frame processing only',
                telemetryTag: 'Local Only',
                tagColor: const Color(0xFF22C55E),
                onTap: () => _showPrivacyDialog(context),
              ),
              _buildInsetDivider(),
              _buildTelemetryTile(
                icon: LucideIcons.code,
                title: 'Open Source Licenses',
                subtitle: 'Flutter, MobileScanner, WebViewFlutter',
                telemetryTag: 'MIT · 14 pkgs',
                tagColor: const Color(0xFF94A3B8),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LicensesScreen(),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // 4. Environment & Telemetry Section
            _buildSectionHeader('ENVIRONMENT & TELEMETRY'),
            const SizedBox(height: 8),
            _buildMachinedPanel([
              _buildTelemetryTile(
                icon: LucideIcons.globe,
                title: 'Default Port & Host',
                subtitle: 'CLI dev server listener',
                telemetryTag: ':8090 · 0.0.0.0',
                tagColor: const Color(0xFF00E5FF),
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: '0.0.0.0:8090'));
                  HapticFeedback.selectionClick();
                  _showToast('Copied host: 0.0.0.0:8090');
                },
              ),
              _buildInsetDivider(),
              _buildTelemetryTile(
                icon: LucideIcons.terminal,
                title: 'Connection Protocol',
                subtitle: 'QR payload URI scheme',
                telemetryTag: 'previewport://v1',
                tagColor: const Color(0xFF94A3B8),
                onTap: () {
                  Clipboard.setData(
                    const ClipboardData(text: 'previewport://connect?v=1'),
                  );
                  HapticFeedback.selectionClick();
                  _showToast('Copied protocol: previewport://connect?v=1');
                },
              ),
            ]),

            const SizedBox(height: 36),

            Center(
              child: Text(
                'PREVIEWPORT · INDUSTRIAL DEV PLAYER',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                  letterSpacing: 1.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMachinedPanel(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E2638),
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInsetDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 48),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFF141A26),
      ),
    );
  }

  Widget _buildTelemetryTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String telemetryTag,
    required Color tagColor,
    required VoidCallback onTap,
  }) {
    return Bounceable(
      scaleFactor: 0.98,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: Colors.transparent,
        child: Row(
          children: [
            // Clean, free-floating vector icon
            Icon(
              icon,
              color: Colors.white,
              size: 21,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            // Monospace telemetry tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: tagColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                telemetryTag,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: tagColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      title: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 2),
      primaryColor: const Color(0xFF00E5FF),
      backgroundColor: const Color(0xFF000000),
      foregroundColor: Colors.white,
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF080B11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E2638)),
        ),
        title: Text(
          'Camera & Privacy',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Camera Usage:',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PreviewPort uses your device camera solely for real-time QR code detection on-device. Camera frames are processed in memory and are never recorded, saved, or uploaded to any servers.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Network Connectivity:',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'When you scan a QR code, the app connects directly to the specified local network IP or URL. No personal identifiers or analytics tracking are collected.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Close'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }
}
