import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../models/session_item.dart';
import '../../widgets/share_qr_modal.dart';

class HistoryTab extends StatefulWidget {
  final List<SessionItem> history;
  final void Function(String url, {String? title}) onLaunchApp;
  final void Function(SessionItem item) onLongPressItem;

  const HistoryTab({
    super.key,
    required this.history,
    required this.onLaunchApp,
    required this.onLongPressItem,
  });

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase();
    final filtered = widget.history.where((e) {
      return e.title.toLowerCase().contains(query) ||
          e.url.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scan History',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '${filtered.length} total',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF00E5FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 250.ms),

          const SizedBox(height: 12),

          // Search Field with Subtle Slate Border and Lucide Search Icon
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search scanned projects...',
              hintStyle: const TextStyle(color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFF000000),
              prefixIcon: const Icon(
                LucideIcons.search,
                color: Color(0xFF00E5FF),
                size: 16,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF1E2638)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF1E2638)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF00E5FF),
                  width: 1.2,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 80.ms, duration: 300.ms),

          const SizedBox(height: 16),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF080B11),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1E2638),
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            _searchQuery.isNotEmpty
                                ? LucideIcons.search_x
                                : LucideIcons.clock,
                            color: const Color(0xFF64748B),
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No Matching Projects'
                              : 'No Scan History',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No projects match "$_searchQuery"'
                              : r'Run $ previewport in your terminal to see sessions here',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms)
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filtered[index];

                      return Slidable(
                            key: ValueKey(item.id),
                            endActionPane: ActionPane(
                              motion: const ScrollMotion(),
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
                                  onPressed: (_) =>
                                      widget.onLongPressItem(item),
                                  backgroundColor: const Color(0xFF334155),
                                  foregroundColor: Colors.white,
                                  icon: LucideIcons.pencil,
                                  label: 'Rename',
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ],
                            ),
                            child: Bounceable(
                              scaleFactor: 0.98,
                              onTap: () => widget.onLaunchApp(
                                item.url,
                                title: item.title,
                              ),
                              onLongPress: () => widget.onLongPressItem(item),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    _buildAppLogo(item.url),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            item.url,
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 11,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(
                            duration: 280.ms,
                            delay: Duration(milliseconds: index * 35),
                          )
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          );
                    },
                  ),
          ),
        ],
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
}
