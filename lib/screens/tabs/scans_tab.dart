import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide ShimmerEffect;
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../models/session_item.dart';
import '../../widgets/hero_scan_card.dart';
import '../../widgets/share_qr_modal.dart';

class ScansTab extends StatelessWidget {
  final List<SessionItem> history;
  final bool isLoading;
  final VoidCallback onOpenScanner;
  final void Function(String url, {String? title}) onLaunchApp;
  final void Function(SessionItem item) onLongPressItem;
  final void Function(SessionItem item)? onDeleteItem;

  const ScansTab({
    super.key,
    required this.history,
    required this.isLoading,
    required this.onOpenScanner,
    required this.onLaunchApp,
    required this.onLongPressItem,
    this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 100),
      children: [
        const SizedBox(height: 6),

        // CENTERPIECE: Frosted Glass Hero Card with spring entrance animation
        HeroScanCard(onTap: onOpenScanner)
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOutCubic),

        const SizedBox(height: 32),

        // Section Title: "Recent Scans"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Scans',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            if (history.isNotEmpty)
              Text(
                '${history.length} items',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF00E5FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

        const SizedBox(height: 14),

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
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF1E2638),
                width: 1.0,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF080B11),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1E2638),
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.scan_line,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Recent Scans',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r'Scanned sessions from $ previewport will appear here',
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
                        subtitle: item.url,
                        onTap: () => onLaunchApp(item.url, title: item.title),
                        onLongPress: () => onLongPressItem(item),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(
                    duration: 280.ms,
                    delay: Duration(milliseconds: index * 40),
                  )
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  );
            }).toList(),
          ),

        const SizedBox(height: 40),
      ],
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
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF1E2638),
          width: 1,
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

  Widget _buildShowcaseRow({
    required BuildContext context,
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Bounceable(
      scaleFactor: 0.98,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
