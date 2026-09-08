import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TerminalLogEntry {
  final String id;
  final String message;
  final String level; // 'info' | 'warn' | 'error'
  final String source; // 'flutter' | 'web'
  final DateTime timestamp;

  TerminalLogEntry({
    required this.id,
    required this.message,
    this.level = 'info',
    this.source = 'flutter',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isError => level == 'error';
  bool get isWarn => level == 'warn';
}

class MiniTerminalDrawer extends StatefulWidget {
  final List<TerminalLogEntry> logs;
  final VoidCallback onClear;
  final VoidCallback onClose;

  const MiniTerminalDrawer({
    super.key,
    required this.logs,
    required this.onClear,
    required this.onClose,
  });

  @override
  State<MiniTerminalDrawer> createState() => _MiniTerminalDrawerState();
}

class _MiniTerminalDrawerState extends State<MiniTerminalDrawer> {
  String _selectedFilter = 'all'; // 'all' | 'error' | 'flutter' | 'web'
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<TerminalLogEntry> get _filteredLogs {
    List<TerminalLogEntry> logs;
    if (_selectedFilter == 'error') {
      logs = widget.logs.where((l) => l.isError).toList();
    } else if (_selectedFilter == 'flutter') {
      logs = widget.logs.where((l) => l.source == 'flutter').toList();
    } else if (_selectedFilter == 'web') {
      logs = widget.logs.where((l) => l.source == 'web').toList();
    } else {
      logs = widget.logs;
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      logs = logs.where((l) => l.message.toLowerCase().contains(q)).toList();
    }

    return logs;
  }

  void _copyAllLogs() {
    final text = widget.logs
        .map((l) => '[${l.timestamp.toIso8601String().substring(11, 19)}] [${l.level.toUpperCase()}] ${l.message}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF161616),
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Logs copied to clipboard',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final drawerHeight = (mq.size.height * 0.65).clamp(360.0, 680.0);

    return Container(
      height: drawerHeight,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xF70A0A0A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.previewBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              const Icon(Icons.terminal_rounded, size: 18, color: AppTheme.cyan),
              const SizedBox(width: 8),
              Text(
                'Live Console',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.logs.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textSecondary),
                onPressed: _copyAllLogs,
                tooltip: 'Copy all logs',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppTheme.textSecondary),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onClear();
                },
                tooltip: 'Clear logs',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
                onPressed: widget.onClose,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Filter chips
          Row(
            children: [
              _buildFilterChip('all', 'All (${widget.logs.length})'),
              const SizedBox(width: 6),
              _buildFilterChip('error', 'Errors (${widget.logs.where((l) => l.isError).length})'),
              const SizedBox(width: 6),
              _buildFilterChip('flutter', 'Flutter'),
              const SizedBox(width: 6),
              _buildFilterChip('web', 'Web'),
            ],
          ),
          const SizedBox(height: 10),

          // Real-time search bar
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _searchQuery.isNotEmpty ? AppTheme.cyan.withValues(alpha: 0.6) : AppTheme.borderSubtle,
              ),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 10, right: 6),
                  child: Icon(Icons.search_rounded, size: 16, color: AppTheme.textMuted),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search console events...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.cancel_rounded, size: 14, color: AppTheme.textMuted),
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Log Entries List
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF050505),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: _filteredLogs.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'No console events matching "$_searchQuery".'
                            : 'No console events recorded yet.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = _filteredLogs[index];
                        final timeStr = log.timestamp.toIso8601String().substring(11, 19);

                        final badgeColor = log.isError
                            ? AppTheme.danger
                            : log.isWarn
                                ? AppTheme.warning
                                : AppTheme.cyan;

                        return InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: log.message));
                            HapticFeedback.selectionClick();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    color: Color(0xFF555555),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    log.level.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'monospace',
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    log.message,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: log.isError
                                          ? const Color(0xFFFF6B6B)
                                          : log.isWarn
                                              ? const Color(0xFFFFD166)
                                              : const Color(0xFFE0E0E0),
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = key);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cyan.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.cyan : AppTheme.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.cyan : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
