import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
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
            left: 24,
            right: 24,
            top: 28,
            bottom: 112,
          ),
          children: [
            Text(
              'Settings',
              style: AppTypography.displayHero(),
            ),
            const SizedBox(height: 8),
            Text(
              'A few details about your PreviewPort workspace.',
              style: AppTypography.subtitle(),
            ),
            const SizedBox(height: 36),

            _buildSection(
              title: 'Connection',
              children: [
                _buildSettingRow(
                  icon: PhosphorIconsRegular.globe,
                  title: 'Default port & host',
                  subtitle: 'CLI development server listener',
                  trailing: '8090',
                  onTap: () {
                    Clipboard.setData(
                      const ClipboardData(text: '0.0.0.0:8090'),
                    );
                    HapticFeedback.selectionClick();
                    _showToast('Copied host: 0.0.0.0:8090');
                  },
                ),
                _buildSettingRow(
                  icon: PhosphorIconsRegular.terminalWindow,
                  title: 'Connection protocol',
                  subtitle: 'QR payload URI scheme',
                  trailing: 'v1',
                  onTap: () {
                    Clipboard.setData(
                      const ClipboardData(text: 'previewport://connect?v=1'),
                    );
                    HapticFeedback.selectionClick();
                    _showToast('Copied PreviewPort protocol');
                  },
                ),
              ],
            ),
            const SizedBox(height: 34),

            _buildSection(
              title: 'Storage',
              children: [
                _buildSettingRow(
                  icon: PhosphorIconsRegular.clock,
                  title: 'Session history',
                  subtitle: 'Saved local preview connections',
                  trailing:
                      '$_sessionCount ${_sessionCount == 1 ? 'item' : 'items'}',
                  onTap: () => HistoryManagementModal.show(
                    context,
                    onUpdated: _loadHistoryCount,
                  ),
                ),
                _buildSettingRow(
                  icon: PhosphorIconsRegular.hardDrive,
                  title: 'Web cache',
                  subtitle: 'Temporary assets and cookies',
                  trailing: 'Manage',
                  onTap: () => CacheManagementModal.show(
                    context,
                    onCleared: () {
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),

            _buildSection(
              title: 'Privacy',
              children: [
                _buildSettingRow(
                  icon: PhosphorIconsRegular.shieldCheck,
                  title: 'Camera & network',
                  subtitle: 'On-device processing and local connections',
                  trailing: 'Local only',
                  onTap: () => _showPrivacyDialog(context),
                ),
                _buildSettingRow(
                  icon: PhosphorIconsRegular.code,
                  title: 'Open-source licenses',
                  subtitle: 'Libraries used by PreviewPort',
                  trailing: 'View',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LicensesScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),

            _buildSection(
              title: 'About',
              children: [
                _buildSettingRow(
                  icon: PhosphorIconsRegular.info,
                  title: 'PreviewPort',
                  subtitle: 'Flutter preview player',
                  trailing: 'v1.0.0',
                ),
              ],
            ),
            const SizedBox(height: 38),
            Center(
              child: Text(
                'PREVIEWPORT',
                style: AppTypography.sectionHud(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 1, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.sectionHud(color: AppTheme.textMuted),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.previewBorder),
              bottom: BorderSide(color: AppTheme.previewBorder),
            ),
          ),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 46),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: AppTheme.borderSubtle,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String trailing,
    VoidCallback? onTap,
  }) {
    final content = Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.transparent,
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Icon(
              icon,
              size: 18,
              color: onTap == null
                  ? AppTheme.textMuted
                  : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTypography.itemTitle(),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.subtitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            trailing,
            style: AppTypography.monoData(color: AppTheme.textMuted),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(
              PhosphorIconsRegular.caretRight,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ],
        ],
      ),
    );

    final row = onTap == null
        ? content
        : Bounceable(
            scaleFactor: 0.99,
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: content,
          );

    return Semantics(
      button: onTap != null,
      label: '$title, $trailing',
      hint: onTap == null ? null : 'Opens $title',
      child: row,
    );
  }

  void _showToast(String message) {
    AppToast.info(context, title: message);
  }

  void _showPrivacyDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.68,
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 34,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppTheme.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Privacy',
                            style: AppTypography.headline(),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'A clear view of how PreviewPort handles access.',
                            style: AppTypography.subtitle(),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        PhosphorIconsRegular.x,
                        size: 19,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'CAMERA',
                  style: AppTypography.sectionHud(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                _buildPrivacyRow(
                  icon: PhosphorIconsRegular.qrCode,
                  title: 'QR detection',
                  body: 'Camera frames are processed on this device.',
                  status: 'On-device',
                ),
                const SizedBox(height: 24),
                Text(
                  'NETWORK',
                  style: AppTypography.sectionHud(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                _buildPrivacyRow(
                  icon: PhosphorIconsRegular.broadcast,
                  title: 'Preview connection',
                  body: 'Your phone connects directly to the scanned URL.',
                  status: 'Direct',
                ),
                const Divider(height: 1, color: AppTheme.borderSubtle),
                _buildPrivacyRow(
                  icon: PhosphorIconsRegular.eyeSlash,
                  title: 'Tracking',
                  body: 'No analytics or personal identifiers are collected.',
                  status: 'None',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyRow({
    required IconData icon,
    required String title,
    required String body,
    required String status,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.itemTitle(fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTypography.subtitle(fontSize: 11.5, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            status,
            style: AppTypography.monoData(color: AppTheme.cyan),
          ),
        ],
      ),
    );
  }
}
