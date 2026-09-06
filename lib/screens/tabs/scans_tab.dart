import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/session_item.dart';
import '../../services/network_status_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hero_scan_card.dart';
import '../../widgets/share_qr_modal.dart';

class ScansTab extends StatelessWidget {
  final List<SessionItem> history;
  final bool isLoading;
  final VoidCallback onOpenScanner;
  final VoidCallback onPasteUrl;
  final VoidCallback onEnterUrl;
  final VoidCallback onCopyCommand;
  final bool isScannerBusy;
  final NetworkStatusService? networkService;
  final void Function(String url, {String? title}) onLaunchApp;
  final void Function(SessionItem item) onLongPressItem;
  final void Function(SessionItem item)? onDeleteItem;
  final Uint8List? capturedPhotoBytes;
  final VoidCallback? onDismissCapturedPhoto;

  const ScansTab({
    super.key,
    required this.history,
    required this.isLoading,
    required this.onOpenScanner,
    required this.onPasteUrl,
    required this.onEnterUrl,
    required this.onCopyCommand,
    this.isScannerBusy = false,
    this.networkService,
    required this.onLaunchApp,
    required this.onLongPressItem,
    this.onDeleteItem,
    this.capturedPhotoBytes,
    this.onDismissCapturedPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(left: 22, right: 22, top: 26, bottom: 120),
      children: [
        const SizedBox(height: 2),

        HeroScanCard(
              onTap: onOpenScanner,
              onPasteUrl: onPasteUrl,
              onEnterUrl: onEnterUrl,
              onCopyCommand: onCopyCommand,
              isBusy: isScannerBusy,
              networkService: networkService,
            )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOutCubic),

        const SizedBox(height: 38),

        if (capturedPhotoBytes != null) ...[
          _buildCapturedPhotoCard(context),
          const SizedBox(height: 24),
        ],

        Row(
          children: [
            Text(
              'Recent previews',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

        const SizedBox(height: 12),

        // Skeleton Shimmer Loading or List View
        if (isLoading)
          Skeletonizer(
            enabled: true,
            effect: ShimmerEffect(
              baseColor: const Color(0xFF111111),
              highlightColor: const Color(0x4000E5FF),
              duration: const Duration(milliseconds: 1200),
            ),
            child: Column(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildShowcaseRow(
                    context: context,
                    iconWidget: _buildAppLogo(''),
                    title: 'Loading Project...',
                    subtitle: 'Connecting...',
                    onTap: () {},
                  ),
                ),
              ),
            ),
          )
        else if (history.isEmpty)
          // Consistent Minimalist Empty State
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
            decoration: BoxDecoration(
              color: AppTheme.previewSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.previewBorder),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 40,
                      height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.previewSurfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.previewBorder,
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.scan_line,
                      color: Color(0xFF64748B),
                      size: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No previews yet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Run previewport start to begin.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 300.ms)
        else
          Column(
            children: history.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Slidable(
                      key: ValueKey(item.id),
                      endActionPane: ActionPane(
                        motion: const BehindMotion(),
                        extentRatio: 0.44,
                        children: [
                          SlidableAction(
                            onPressed: (_) => ShareQrModal.show(
                              context,
                              url: item.url,
                              title: item.title,
                            ),
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            icon: LucideIcons.qr_code,
                            label: 'Share',
                            borderRadius: BorderRadius.circular(16),
                          ),
                          SlidableAction(
                            onPressed: (_) => onLongPressItem(item),
                            backgroundColor: const Color(0xFF334155),
                            foregroundColor: Colors.white,
                            icon: LucideIcons.pencil,
                            label: 'Rename',
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ],
                      ),
                      child: _buildShowcaseRow(
                        context: context,
                        iconWidget: _buildAppLogo(item.url),
                        title: item.title,
                        subtitle:
                            '${_formatEndpoint(item.url)} · ${item.timeAgo}',
                        onTap: () => onLaunchApp(item.url, title: item.title),
                        onLongPress: () => onLongPressItem(item),
                        semanticLabel: 'Open ${item.title} preview',
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(
                    duration: 280.ms,
                    delay: Duration(milliseconds: index * 40),
                  )
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
            }).toList(),
          ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCapturedPhotoCard(BuildContext context) {
    return Semantics(
      label: 'Captured photo preview',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.previewSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.previewBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                capturedPhotoBytes!,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 72,
                  height: 72,
                  color: AppTheme.previewSurfaceElevated,
                  child: const Icon(
                    LucideIcons.image_off,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Photo captured',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ready for your next action',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismissCapturedPhoto,
              tooltip: 'Remove captured photo',
              icon: const Icon(
                LucideIcons.x,
                color: AppTheme.textMuted,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogo(String url) {
    final uri = Uri.tryParse(url);
    final faviconUrl = (uri != null && uri.hasScheme && uri.hasAuthority)
        ? (uri.host == 'localhost' ||
                  uri.host == '127.0.0.1' ||
                  uri.host.startsWith('192.168.'))
              ? '${uri.scheme}://${uri.host}:${uri.port}/favicon.png'
              : 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=128'
        : null;

    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppTheme.previewSurfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.previewBorder, width: 1),
      ),
      child: faviconUrl != null
          ? Image.network(
              faviconUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholderLogo(),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _buildPlaceholderLogo();
              },
            )
          : _buildPlaceholderLogo(),
    );
  }

  Widget _buildPlaceholderLogo() {
    return Image.asset(
      'assets/previewport-logo-transparent.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }

  Widget _buildShowcaseRow({
    required BuildContext context,
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    String? semanticLabel,
  }) {
    final row = Bounceable(
      scaleFactor: 0.98,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.previewSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.previewBorder),
        ),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10.5,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.chevron_right,
              size: 18,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      label: semanticLabel ?? title,
      hint: 'Double tap to launch this preview',
      child: row,
    );
  }

  String _formatEndpoint(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;

    final defaultPort =
        (uri.scheme == 'https' && uri.port == 443) ||
        (uri.scheme == 'http' && uri.port == 80);
    final port = uri.hasPort && !defaultPort ? ':${uri.port}' : '';
    final path = uri.path.isNotEmpty && uri.path != '/' ? uri.path : '';
    return '${uri.host}$port$path';
  }
}
