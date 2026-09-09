import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../models/session_item.dart';
import '../../services/history_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/share_qr_modal.dart';

class HistoryTab extends StatefulWidget {
  final List<SessionItem> history;
  final void Function(String url, {String? title, String? controlUrl}) onLaunchApp;
  final void Function(SessionItem item) onLongPressItem;
  final Future<void> Function()? onRefresh;
  final void Function(SessionItem item)? onDeleteItem;

  const HistoryTab({
    super.key,
    required this.history,
    required this.onLaunchApp,
    required this.onLongPressItem,
    this.onRefresh,
    this.onDeleteItem,
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
                        style: AppTypography.displayHero(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your recent Flutter previews.',
                        style: AppTypography.subtitle(),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${filtered.length}',
                  style: AppTypography.monoCounter(),
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildSearchField(),
            const SizedBox(height: 22),
            Expanded(
              child: widget.onRefresh != null
                  ? RefreshIndicator(
                      onRefresh: () async {
                        HapticFeedback.mediumImpact();
                        await widget.onRefresh?.call();
                      },
                      color: AppTheme.cyan,
                      backgroundColor: const Color(0xFF141414),
                      child: filtered.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
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
                    )
                  : filtered.isEmpty
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
        style: AppTypography.body(),
        cursorColor: AppTheme.cyan,
        decoration: InputDecoration(
          hintText: 'Search previews',
          hintStyle: AppTypography.body(color: AppTheme.textMuted),
          prefixIcon: const Icon(
            PhosphorIconsRegular.magnifyingGlass,
            color: AppTheme.textMuted,
            size: 18,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () => setState(() => _searchQuery = ''),
                  icon: const Icon(
                    PhosphorIconsRegular.x,
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
        motion: const BehindMotion(),
        extentRatio: 0.62,
        children: [
          CustomSlidableAction(
            onPressed: (_) =>
                ShareQrModal.show(context, url: item.url, title: item.title),
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x2200E5FF),
                borderRadius: BorderRadius.circular(14),
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
                      size: 16,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Share',
                      style: AppTypography.actionLabel(color: AppTheme.cyan),
                    ),
                  ],
                ),
              ),
            ),
          ),
          CustomSlidableAction(
            onPressed: (_) => widget.onLongPressItem(item),
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x18FFFFFF),
                borderRadius: BorderRadius.circular(14),
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
                      size: 16,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Rename',
                      style: AppTypography.actionLabel(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          CustomSlidableAction(
            onPressed: (_) async {
              HapticFeedback.mediumImpact();
              if (widget.onDeleteItem != null) {
                widget.onDeleteItem!(item);
              } else {
                await HistoryService.removeSession(item.id);
                await widget.onRefresh?.call();
                if (context.mounted) {
                  AppToast.info(context, title: 'Preview removed');
                }
              }
            },
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x22EF4444),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0x44EF4444),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      PhosphorIconsRegular.trash,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Delete',
                      style: AppTypography.actionLabel(
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            widget.onLaunchApp(item.url, title: item.title, controlUrl: item.controlUrl);
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
                        style: AppTypography.itemTitle(),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_endpoint(item.url)}  ·  ${item.timeAgo}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.monoData(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  PhosphorIconsRegular.caretRight,
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.12),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x15FFFFFF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0x24FFFFFF),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Icon(
                    searching ? PhosphorIconsRegular.magnifyingGlass : PhosphorIconsRegular.clock,
                    color: AppTheme.textMuted,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                searching ? 'No matching previews' : 'No previews yet',
                style: AppTypography.cardTitle(),
              ),
              const SizedBox(height: 6),
              Text(
                searching
                    ? 'Try another project name or endpoint.'
                    : 'Run pp start to begin.',
                textAlign: TextAlign.center,
                style: AppTypography.subtitle(),
              ),
            ],
          ),
        ),
      ],
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
      child: faviconUrl != null
          ? Image.network(
              faviconUrl,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (frame == null) {
                  return _buildPlaceholderLogo();
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: child,
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholderLogo(),
            )
          : _buildPlaceholderLogo(),
    );
  }

  Widget _buildPlaceholderLogo() {
    return Center(
      child: Image.asset(
        'assets/previewport-logo-transparent.png',
        width: 26,
        height: 26,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
