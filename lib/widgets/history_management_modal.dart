import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:toastification/toastification.dart';

import '../models/session_item.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

class HistoryManagementModal extends StatefulWidget {
  final VoidCallback onUpdated;

  const HistoryManagementModal({super.key, required this.onUpdated});

  static void show(BuildContext context, {required VoidCallback onUpdated}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => HistoryManagementModal(onUpdated: onUpdated),
    );
  }

  @override
  State<HistoryManagementModal> createState() => _HistoryManagementModalState();
}

class _HistoryManagementModalState extends State<HistoryManagementModal> {
  List<SessionItem> _items = [];
  bool _isLoading = true;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final list = await HistoryService.getHistory();
    if (!mounted) return;
    setState(() {
      _items = list;
      _isLoading = false;
    });
  }

  Future<void> _deleteSingle(SessionItem item) async {
    HapticFeedback.lightImpact();
    await HistoryService.removeSession(item.id);
    _selectedIds.remove(item.id);
    await _loadItems();
    widget.onUpdated();

    if (!mounted) return;
    _showToast('Removed ${item.title}');
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.mediumImpact();
    final count = _selectedIds.length;
    for (final id in _selectedIds.toList()) {
      await HistoryService.removeSession(id);
    }
    _selectedIds.clear();
    await _loadItems();
    widget.onUpdated();

    if (!mounted) return;
    _showToast('Removed $count ${count == 1 ? 'preview' : 'previews'}');
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.previewSurfaceElevated,
        title: Text(
          'Clear session history?',
          style: GoogleFonts.inter(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This removes the saved preview connections from this device.',
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
              'Clear history',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _clearAll();
  }

  Future<void> _clearAll() async {
    HapticFeedback.mediumImpact();
    await HistoryService.clearAll();
    _selectedIds.clear();
    await _loadItems();
    widget.onUpdated();

    if (!mounted) return;
    Navigator.of(context).pop();
    _showToast('Session history cleared');
  }

  void _showToast(String message) {
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      title: Text(
        message,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
          fontSize: 13,
        ),
      ),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 2),
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
        height: media.size.height * 0.78,
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
                            'Session history',
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Saved preview connections on this device.',
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
                Text(
                  '${_items.length} ${_items.length == 1 ? 'preview' : 'previews'}',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(child: _buildContent()),
                if (_items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  if (_selectedIds.isNotEmpty)
                    _buildActionRow(
                      label: 'Delete ${_selectedIds.length} selected',
                      icon: LucideIcons.trash_2,
                      color: AppTheme.textSecondary,
                      onTap: _deleteSelected,
                    ),
                  _buildActionRow(
                    label: 'Clear all history',
                    icon: LucideIcons.trash,
                    color: AppTheme.danger,
                    onTap: _confirmClearAll,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.clock_3,
              color: AppTheme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 14),
            Text(
              'No saved previews',
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Run pp start to begin.',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _items.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppTheme.borderSubtle),
      itemBuilder: (context, index) {
        final item = _items[index];
        final selected = _selectedIds.contains(item.id);
        return Semantics(
          container: true,
          label: '${item.title}, ${item.url}, ${item.timeAgo}',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (selected) {
                          _selectedIds.remove(item.id);
                        } else {
                          _selectedIds.add(item.id);
                        }
                      });
                    },
                    activeColor: AppTheme.cyan,
                    checkColor: Colors.black,
                    side: const BorderSide(color: AppTheme.textMuted),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 12),
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
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${item.url}  ·  ${item.timeAgo}',
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
                IconButton(
                  tooltip: 'Remove ${item.title}',
                  onPressed: () => _deleteSingle(item),
                  icon: const Icon(
                    LucideIcons.trash_2,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionRow({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(LucideIcons.chevron_right, size: 15, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
