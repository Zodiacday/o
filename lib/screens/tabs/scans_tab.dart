import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/session_item.dart';
import '../../models/nearby_preview.dart';
import '../../services/network_status_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hero_scan_card.dart';
import '../../widgets/share_qr_modal.dart';

class ScansTab extends StatelessWidget {
  final ScrollController? scrollController;
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
  final List<NearbyPreview> nearbyPreviews;
  final void Function(NearbyPreview preview)? onOpenNearbyPreview;

  const ScansTab({
    super.key,
    this.scrollController,
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
    this.nearbyPreviews = const [],
    this.onOpenNearbyPreview,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
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

        if (nearbyPreviews.isNotEmpty) ...[
          Row(
            children: [
              const Icon(LucideIcons.radio, size: 15, color: AppTheme.cyan),
              const SizedBox(width: 7),
              Text(
                'Nearby previews',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 80.ms, duration: 300.ms),
          const SizedBox(height: 12),
          ...nearbyPreviews.asMap().entries.map((entry) {
            final index = entry.key;
            final preview = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildShowcaseRow(
                context: context,
                iconWidget: _buildNearbyLogo(),
                title: preview.projectName,
                subtitle: '${preview.displayEndpoint} · Available now',
                onTap: () => onOpenNearbyPreview?.call(preview),
                semanticLabel: 'Open nearby ${preview.projectName} preview',
              ),
            ).animate().fadeIn(
              delay: Duration(milliseconds: 100 + index * 40),
              duration: 280.ms,
            );
          }),
          const SizedBox(height: 26),
        ],

        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.cyan,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Recent previews',
              style: AppTypography.sectionHud(color: AppTheme.textSecondary),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 22),
            decoration: BoxDecoration(
              color: const Color(0xFF080808),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0x1F38BDF8),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cyan.withValues(alpha: 0.03),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0x1400E5FF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x3800E5FF),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.terminal,
                      size: 22,
                      color: AppTheme.cyan,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No previews yet',
                  style: AppTypography.cardTitle(),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Run pp start in your Flutter project root or scan a terminal QR code to launch your live preview.',
                    textAlign: TextAlign.center,
                    style: AppTypography.subtitle(color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 20),
                Bounceable(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onCopyCommand();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1800E5FF),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0x4000E5FF),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.copy, size: 14, color: AppTheme.cyan),
                        const SizedBox(width: 8),
                        Text(
                          'pp start',
                          style: AppTypography.code(),
                        ),
                        Text(
                          ' · Copy',
                          style: AppTypography.body(
                            color: AppTheme.cyan.withValues(alpha: 0.75),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 150.ms, duration: 350.ms)
              .scale(begin: const Offset(0.97, 0.97), curve: Curves.easeOutCubic)
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
      width: 42,
      height: 42,
      padding: const EdgeInsets.all(7.5),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFF1E2638),
          width: 0.8,
        ),
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

  Widget _buildNearbyLogo() {
    return Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppTheme.cyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.35)),
      ),
      child: Image.asset(
        'assets/previewport-logo-transparent.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
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
          color: const Color(0xFF080808),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF1E2638).withValues(alpha: 0.8),
            width: 0.8,
          ),
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
                    style: GoogleFonts.shareTechMono(
                      fontSize: 11,
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
              size: 16,
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
