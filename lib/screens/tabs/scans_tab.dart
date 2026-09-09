import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/session_item.dart';
import '../../models/nearby_preview.dart';
import '../../services/network_status_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/hero_scan_card.dart';
import '../../widgets/ambient_resume_card.dart';
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
  final void Function(String url, {String? title, String? controlUrl}) onLaunchApp;
  final void Function(SessionItem item) onLongPressItem;
  final void Function(SessionItem item)? onDeleteItem;
  final Uint8List? capturedPhotoBytes;
  final VoidCallback? onDismissCapturedPhoto;
  final List<NearbyPreview> nearbyPreviews;
  final void Function(NearbyPreview preview)? onOpenNearbyPreview;
  final Future<void> Function()? onRefresh;

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
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(left: 22, right: 22, top: 66, bottom: 120),
      children: [
        const SizedBox(height: 2),

        if (nearbyPreviews.isNotEmpty)
          AmbientResumeCard(
            preview: nearbyPreviews.first,
            onResume: () => onOpenNearbyPreview?.call(nearbyPreviews.first),
            onScanQr: onOpenScanner,
          )
              .animate()
              .fadeIn(duration: 350.ms)
              .scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOutCubic)
        else
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

        if (nearbyPreviews.length > 1) ...[
          Row(
            children: [
              const Icon(PhosphorIconsRegular.broadcast, size: 15, color: AppTheme.cyan),
              const SizedBox(width: 7),
              Text(
                'Other nearby previews',
                style: AppTypography.sectionHud(color: AppTheme.cyan),
              ),
            ],
          ).animate().fadeIn(delay: 80.ms, duration: 300.ms),
          const SizedBox(height: 12),
          ...nearbyPreviews.skip(1).map((preview) {
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
            );
          }),
          const SizedBox(height: 26),
        ],

        Row(
          children: [
            Text(
              'Recent previews',
              style: AppTypography.sectionHud(),
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
          _buildTactileEmptyState(context)
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
                        extentRatio: 0.46,
                        children: [
                          CustomSlidableAction(
                            onPressed: (_) => ShareQrModal.show(
                              context,
                              url: item.url,
                              title: item.title,
                            ),
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 3,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0x2200E5FF),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: const Color(0x4400E5FF),
                                  width: 0.8,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      PhosphorIconsRegular.qrCode,
                                      color: AppTheme.cyan,
                                      size: 17,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Share',
                                      style: AppTypography.actionLabel(
                                        color: AppTheme.cyan,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          CustomSlidableAction(
                            onPressed: (_) => onLongPressItem(item),
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 3,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0x18FFFFFF),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: const Color(0x28FFFFFF),
                                  width: 0.8,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      PhosphorIconsRegular.pencilSimple,
                                      color: Colors.white,
                                      size: 17,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rename',
                                      style: AppTypography.actionLabel(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      child: _buildShowcaseRow(
                        context: context,
                        iconWidget: _buildAppLogo(item.url),
                        title: item.title,
                        subtitle:
                            '${_formatEndpoint(item.url)} · ${item.timeAgo}',
                        onTap: () => onLaunchApp(item.url, title: item.title, controlUrl: item.controlUrl),
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

    return onRefresh != null
        ? RefreshIndicator(
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              await onRefresh?.call();
            },
            color: AppTheme.cyan,
            backgroundColor: const Color(0xFF141414),
            child: list,
          )
        : list;
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
                    PhosphorIconsRegular.imageBroken,
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
                PhosphorIconsRegular.x,
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

    if (faviconUrl != null) {
      return Image.network(
        faviconUrl,
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame == null) {
            return _buildPlaceholderLogo();
          }
          return Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.previewSurfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.previewBorder, width: 1),
            ),
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderLogo(),
      );
    }

    return _buildPlaceholderLogo();
  }

  Widget _buildPlaceholderLogo() {
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: Image.asset(
          'assets/previewport-logo-transparent.png',
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  Widget _buildNearbyLogo() {
    return _buildPlaceholderLogo();
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
                    style: AppTypography.itemTitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.monoData(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              PhosphorIconsRegular.caretRight,
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

  Widget _buildTactileEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: const Color(0x3814161C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x2E00E5FF),
          width: 0.85,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1400E5FF),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x1A00E5FF),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0x4000E5FF),
                width: 0.8,
              ),
            ),
            child: const Center(
              child: Icon(
                PhosphorIconsRegular.terminalWindow,
                size: 20,
                color: AppTheme.cyan,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No previews yet',
            style: AppTypography.cardTitle(),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Run pp start in your Flutter project root or scan a terminal QR code to launch your live preview.',
              textAlign: TextAlign.center,
              style: AppTypography.subtitle(),
            ),
          ),
          const SizedBox(height: 16),
          Bounceable(
            onTap: onCopyCommand,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x1800E5FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0x4D00E5FF),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    PhosphorIconsRegular.copy,
                    size: 13,
                    color: AppTheme.cyan,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'pp start',
                    style: AppTypography.monoCommand(),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '· Copy',
                    style: AppTypography.subtitle(
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 320.ms).scale(
          begin: const Offset(0.98, 0.98),
          curve: Curves.easeOutCubic,
        );
  }
}
