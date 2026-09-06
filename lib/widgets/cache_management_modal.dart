import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:toastification/toastification.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';

class CacheOption {
  final String id;
  final String title;
  final String subtitle;
  final double sizeMb;
  final IconData icon;

  const CacheOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sizeMb,
    required this.icon,
  });
}

class CacheManagementModal extends StatefulWidget {
  final VoidCallback onCleared;

  const CacheManagementModal({super.key, required this.onCleared});

  static void show(BuildContext context, {required VoidCallback onCleared}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CacheManagementModal(onCleared: onCleared),
    );
  }

  @override
  State<CacheManagementModal> createState() => _CacheManagementModalState();
}

class _CacheManagementModalState extends State<CacheManagementModal> {
  static const List<CacheOption> _options = [
    CacheOption(
      id: 'bundles',
      title: 'Preview assets',
      subtitle: 'Web files kept for faster reloads',
      sizeMb: 2.6,
      icon: LucideIcons.file_code,
    ),
    CacheOption(
      id: 'cookies',
      title: 'Session data',
      subtitle: 'Cookies and temporary connection state',
      sizeMb: 0.4,
      icon: LucideIcons.cookie,
    ),
    CacheOption(
      id: 'storage',
      title: 'Local preferences',
      subtitle: 'Temporary values used by a preview',
      sizeMb: 0.8,
      icon: LucideIcons.database,
    ),
  ];

  double get _totalSize =>
      _options.fold(0.0, (total, option) => total + option.sizeMb);

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.previewSurfaceElevated,
        title: Text(
          'Clear web cache?',
          style: GoogleFonts.inter(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Temporary preview data will be removed. Your session history will stay intact.',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Clear cache',
              style: TextStyle(color: AppTheme.cyan),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) await _performClear();
  }

  Future<void> _performClear() async {
    HapticFeedback.mediumImpact();

    try {
      await WebViewCookieManager().clearCookies();
    } catch (_) {
      // The webview platform may not be available on every desktop target.
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onCleared();

    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: Text(
        'Web cache cleared',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
          fontSize: 13,
        ),
      ),
      description: Text(
        'Removed ${_totalSize.toStringAsFixed(1)} MB of temporary data',
        style: GoogleFonts.inter(
          color: AppTheme.textSecondary,
          fontSize: 11,
        ),
      ),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      primaryColor: AppTheme.cyan,
      backgroundColor: AppTheme.previewSurfaceElevated,
      foregroundColor: AppTheme.textPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        height: media.size.height * 0.64,
        color: AppTheme.background,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
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
                            'Web cache',
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Temporary data kept for faster previews.',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        LucideIcons.x,
                        size: 19,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.hard_drive,
                      size: 18,
                      color: AppTheme.cyan,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Estimated storage',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_totalSize.toStringAsFixed(1)} MB',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _options.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      color: AppTheme.borderSubtle,
                    ),
                    itemBuilder: (_, index) {
                      final option = _options[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Icon(
                              option.icon,
                              size: 18,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.title,
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textPrimary,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    option.subtitle,
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${option.sizeMb.toStringAsFixed(1)} MB',
                              style: GoogleFonts.jetBrainsMono(
                                color: AppTheme.textMuted,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  button: true,
                  label: 'Clear web cache',
                  child: InkWell(
                    onTap: _confirmClear,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.trash_2,
                            size: 16,
                            color: AppTheme.cyan,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Clear web cache',
                            style: GoogleFonts.inter(
                              color: AppTheme.cyan,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            LucideIcons.chevron_right,
                            size: 15,
                            color: AppTheme.cyan,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
