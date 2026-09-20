import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../models/session_item.dart';
import '../../theme/app_theme.dart';
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
    final query = _searchQuery.trim().toLowerCase();
    final filtered = widget.history.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.url.toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 104),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan history',
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your recent Flutter previews.',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${filtered.length}',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildSearchField(),
            const SizedBox(height: 22),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        color: AppTheme.borderSubtle,
                      ),
                      itemBuilder: (context, index) =>
                          _buildHistoryRow(context, filtered[index])
                              .animate()
                              .fadeIn(
                                duration: 260.ms,
                                delay: Duration(milliseconds: index * 35),
                              )
                              .slideY(
                                begin: 0.04,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Semantics(
      textField: true,
      label: 'Search preview history',
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
        cursorColor: AppTheme.cyan,
        decoration: InputDecoration(
          hintText: 'Search previews',
          hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14),
          prefixIcon: const Icon(
            LucideIcons.search,
            color: AppTheme.textMuted,
            size: 18,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () => setState(() => _searchQuery = ''),
                  icon: const Icon(
                    LucideIcons.x,
                    color: AppTheme.textSecondary,
                    size: 17,
                  ),
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.previewBorder),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.previewBorder),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.cyan, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryRow(BuildContext context, SessionItem item) {
    return Slidable(
      key: ValueKey(item.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.44,
        children: [
          SlidableAction(
            onPressed: (_) =>
                ShareQrModal.show(context, url: item.url, title: item.title),
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            icon: LucideIcons.qr_code,
            label: 'Share',
          ),
          SlidableAction(
            onPressed: (_) => widget.onLongPressItem(item),
            backgroundColor: const Color(0xFF334155),
            foregroundColor: Colors.white,
            icon: LucideIcons.pencil,
            label: 'Rename',
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label: '${item.title}, ${_endpoint(item.url)}, ${item.timeAgo}',
        hint: 'Opens this preview. Long press to rename.',
        child: Bounceable(
          scaleFactor: 0.99,
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onLaunchApp(item.url, title: item.title);
          },
          onLongPress: () => widget.onLongPressItem(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              children: [
                _buildAppLogo(item.url),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_endpoint(item.url)}  ·  ${item.timeAgo}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          color: AppTheme.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  LucideIcons.chevron_right,
                  size: 17,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final searching = _searchQuery.trim().isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            searching ? LucideIcons.search_x : LucideIcons.clock_3,
            color: AppTheme.textMuted,
            size: 24,
          ),
          const SizedBox(height: 16),
          Text(
            searching ? 'No matching previews' : 'No previews yet',
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? 'Try another project name or endpoint.'
                : 'Run previewport start to begin.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _endpoint(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.host}$port';
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

    return SizedBox(
      width: 34,
      height: 34,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: faviconUrl != null
            ? Image.network(
                faviconUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholderLogo(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _buildPlaceholderLogo();
                },
              )
            : _buildPlaceholderLogo(),
      ),
    );
  }

  Widget _buildPlaceholderLogo() {
    return Container(
      color: AppTheme.previewSurfaceElevated,
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        'assets/previewport-logo-transparent.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
