import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../models/session_item.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/rename_dialog.dart';
import '../widgets/share_qr_modal.dart';

class HistoryScreen extends StatefulWidget {
  final void Function(String url, {String? title, String? controlUrl}) onLaunchApp;

  const HistoryScreen({super.key, required this.onLaunchApp});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SessionItem> _history = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final items = await HistoryService.getHistory();
    if (mounted) {
      setState(() {
        _history = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(SessionItem item) async {
    HapticFeedback.mediumImpact();
    await HistoryService.removeSession(item.id);
    await _loadHistory();
    if (mounted) {
      AppToast.info(
        context,
        title: 'Preview removed',
        description: item.title,
      );
    }
  }

  Future<void> _confirmClearAll() async {
    if (_history.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF14171F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: Text(
          'Clear all history?',
          style: AppTypography.modalTitle(),
        ),
        content: Text(
          'This will permanently remove all ${_history.length} saved previews from this device.',
          style: AppTypography.subtitle(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.button(color: AppTheme.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      await HistoryService.clearAll();
      await _loadHistory();
      if (mounted) {
        AppToast.info(
          context,
          title: 'History cleared',
          description: 'All saved previews have been removed.',
        );
      }
    }
  }

  void _showRenameDialog(SessionItem item) {
    showDialog(
      context: context,
      builder: (_) => RenameDialog(
        item: item,
        onSaved: (newName) async {
          await HistoryService.updateTitle(item.id, newName);
          await _loadHistory();
          if (mounted) {
            AppToast.success(
              context,
              title: 'Renamed',
              description: 'Preview updated to "$newName"',
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _history.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.url.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            PhosphorIconsRegular.arrowLeft,
            color: AppTheme.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Scan History',
          style: AppTypography.headline().copyWith(fontSize: 18),
        ),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              tooltip: 'Clear all history',
              icon: const Icon(
                PhosphorIconsRegular.trash,
                color: AppTheme.textMuted,
                size: 19,
              ),
              onPressed: _confirmClearAll,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SAVED PREVIEWS',
                        style: AppTypography.sectionHud(),
                      ),
                      Text(
                        '${filtered.length} ${_history.length != filtered.length ? 'of ${_history.length}' : ''}',
                        style: AppTypography.monoCounter(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderSubtle),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.cyan,
                        strokeWidth: 2,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      color: AppTheme.cyan,
                      backgroundColor: const Color(0xFF141414),
                      child: filtered.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const Divider(
                                height: 1,
                                color: AppTheme.borderSubtle,
                              ),
                              itemBuilder: (context, index) =>
                                  _buildHistoryRow(context, filtered[index]),
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
          hintText: 'Search by project name or URL…',
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
                  icon: const Icon(
                    PhosphorIconsRegular.x,
                    color: AppTheme.textMuted,
                    size: 16,
                  ),
                  onPressed: () => setState(() => _searchQuery = ''),
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          filled: true,
          fillColor: const Color(0xFF0F131C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.cyan, width: 1.0),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E131E),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: const Icon(
                  PhosphorIconsRegular.clock,
                  color: AppTheme.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No matching previews'
                    : 'No saved previews',
                style: AppTypography.headline().copyWith(fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try searching with a different name or port number.'
                    : 'Previews you open from the Scanner or Quick Connect will appear here.',
                textAlign: TextAlign.center,
                style: AppTypography.subtitle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryRow(BuildContext context, SessionItem item) {
    return Slidable(
      key: ValueKey(item.id),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => ShareQrModal.show(
              context,
              url: item.url,
              title: item.title,
            ),
            backgroundColor: AppTheme.cyan,
            foregroundColor: Colors.black,
            icon: PhosphorIconsRegular.qrCode,
            label: 'Share',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => _deleteItem(item),
            backgroundColor: AppTheme.danger,
            foregroundColor: Colors.white,
            icon: PhosphorIconsRegular.trash,
            label: 'Delete',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Bounceable(
        scaleFactor: 0.98,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onLaunchApp(
            item.url,
            title: item.title,
            controlUrl: item.controlUrl,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          color: Colors.transparent,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C101A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1B2232)),
                ),
                child: const Icon(
                  PhosphorIconsRegular.browsers,
                  size: 18,
                  color: AppTheme.cyan,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.headline().copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.displayUrl} · ${item.timeAgo}',
                      style: AppTypography.monoData(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Rename',
                icon: const Icon(
                  PhosphorIconsRegular.pencilSimple,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                onPressed: () => _showRenameDialog(item),
              ),
              const Icon(
                PhosphorIconsRegular.caretRight,
                size: 14,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
