import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/network_request_entry.dart';
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
  final List<NetworkRequestEntry> networkRequests;
  final VoidCallback onClear;
  final VoidCallback? onClearNetwork;
  final VoidCallback onClose;

  const MiniTerminalDrawer({
    super.key,
    required this.logs,
    this.networkRequests = const [],
    required this.onClear,
    this.onClearNetwork,
    required this.onClose,
  });

  @override
  State<MiniTerminalDrawer> createState() => _MiniTerminalDrawerState();
}

class _MiniTerminalDrawerState extends State<MiniTerminalDrawer> {
  String _activeTab = 'console'; // 'console' | 'network'
  String _selectedLogFilter = 'all'; // 'all' | 'error' | 'flutter' | 'web'
  String _selectedNetworkFilter = 'all'; // 'all' | 'error' | 'slow' | 'fetch' | 'xhr'
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
    if (_selectedLogFilter == 'error') {
      logs = widget.logs.where((l) => l.isError).toList();
    } else if (_selectedLogFilter == 'flutter') {
      logs = widget.logs.where((l) => l.source == 'flutter').toList();
    } else if (_selectedLogFilter == 'web') {
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

  List<NetworkRequestEntry> get _filteredNetworkRequests {
    List<NetworkRequestEntry> list;
    if (_selectedNetworkFilter == 'error') {
      list = widget.networkRequests.where((r) => r.isError).toList();
    } else if (_selectedNetworkFilter == 'slow') {
      list = widget.networkRequests.where((r) => r.isSlow).toList();
    } else if (_selectedNetworkFilter == 'fetch') {
      list = widget.networkRequests.where((r) => r.initiator == 'fetch').toList();
    } else if (_selectedNetworkFilter == 'xhr') {
      list = widget.networkRequests.where((r) => r.initiator == 'xhr').toList();
    } else {
      list = widget.networkRequests;
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((r) {
        return r.url.toLowerCase().contains(q) ||
            r.method.toLowerCase().contains(q) ||
            r.status.toString().contains(q) ||
            r.statusText.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  void _copyAllLogs() {
    final text = widget.logs
        .map((l) =>
            '[${l.timestamp.toIso8601String().substring(11, 19)}] [${l.level.toUpperCase()}] ${l.message}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    _showToast('Logs copied to clipboard');
  }

  void _copyAllNetwork() {
    final text = widget.networkRequests
        .map((r) =>
            '${r.method} ${r.url} - ${r.status} (${r.durationMs}ms)')
        .join('\n');
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    _showToast('Network requests copied to clipboard');
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF161616),
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Color _getStatusColor(int status) {
    if (status >= 200 && status < 300) return const Color(0xFF10B981); // Emerald
    if (status >= 300 && status < 400) return AppTheme.cyan; // Cyan
    if (status >= 400 && status < 500) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Crimson error
  }

  Color _getDurationColor(int durationMs) {
    if (durationMs < 150) return const Color(0xFF10B981);
    if (durationMs < 500) return const Color(0xFFB0B0B0);
    return const Color(0xFFF59E0B);
  }

  void _showRequestDetails(NetworkRequestEntry request) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D0D0D),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.borderSubtle),
      ),
      builder: (ctx) {
        final statusColor = _getStatusColor(request.status);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        request.status == 0 ? 'FAILED' : '${request.status} ${request.statusText}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      request.method,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${request.durationMs}ms',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                        color: _getDurationColor(request.durationMs),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Request URL',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: request.url));
                              HapticFeedback.selectionClick();
                              _showToast('URL copied');
                            },
                            child: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.cyan),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        request.url,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      const Divider(color: Color(0xFF222222), height: 18),
                      Row(
                        children: [
                          Text(
                            'Initiator: ',
                            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textMuted),
                          ),
                          Text(
                            request.initiator.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: AppTheme.cyan,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            request.timestamp.toIso8601String().substring(11, 19),
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cyan.withValues(alpha: 0.15),
                      foregroundColor: AppTheme.cyan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AppTheme.cyan.withValues(alpha: 0.5)),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.terminal_rounded, size: 16),
                    label: Text(
                      'Copy as cURL',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: request.toCurl()));
                      HapticFeedback.mediumImpact();
                      Navigator.of(ctx).pop();
                      _showToast('cURL command copied to clipboard');
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final drawerHeight = (mq.size.height * 0.68).clamp(380.0, 720.0);
    final networkErrors = widget.networkRequests.where((r) => r.isError).length;

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

          // Header with Dual-Tab Switcher
          Row(
            children: [
              // Segmented Switcher
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTabButton(
                      id: 'console',
                      label: 'Live Console',
                      count: widget.logs.length,
                      icon: Icons.terminal_rounded,
                      isActive: _activeTab == 'console',
                    ),
                    const SizedBox(width: 4),
                    _buildTabButton(
                      id: 'network',
                      label: 'Network',
                      count: widget.networkRequests.length,
                      errorCount: networkErrors,
                      icon: Icons.lan_rounded,
                      isActive: _activeTab == 'network',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textSecondary),
                onPressed: _activeTab == 'console' ? _copyAllLogs : _copyAllNetwork,
                tooltip: _activeTab == 'console' ? 'Copy all logs' : 'Copy all requests',
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppTheme.textSecondary),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (_activeTab == 'console') {
                    widget.onClear();
                  } else {
                    if (widget.onClearNetwork != null) {
                      widget.onClearNetwork!();
                    } else {
                      widget.onClear();
                    }
                  }
                },
                tooltip: _activeTab == 'console' ? 'Clear logs' : 'Clear network',
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _activeTab == 'console'
                  ? [
                      _buildFilterChip('all', 'All (${widget.logs.length})'),
                      const SizedBox(width: 6),
                      _buildFilterChip('error', 'Errors (${widget.logs.where((l) => l.isError).length})'),
                      const SizedBox(width: 6),
                      _buildFilterChip('flutter', 'Flutter'),
                      const SizedBox(width: 6),
                      _buildFilterChip('web', 'Web'),
                    ]
                  : [
                      _buildFilterChip('all', 'All (${widget.networkRequests.length})'),
                      const SizedBox(width: 6),
                      _buildFilterChip('error', 'Errors ($networkErrors)'),
                      const SizedBox(width: 6),
                      _buildFilterChip('slow', 'Slow (${widget.networkRequests.where((r) => r.isSlow).length})'),
                      const SizedBox(width: 6),
                      _buildFilterChip('fetch', 'Fetch (${widget.networkRequests.where((r) => r.initiator == 'fetch').length})'),
                      const SizedBox(width: 6),
                      _buildFilterChip('xhr', 'XHR (${widget.networkRequests.where((r) => r.initiator == 'xhr').length})'),
                    ],
            ),
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
                      hintText: _activeTab == 'console'
                          ? 'Search console events...'
                          : 'Search endpoint, method, status...',
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

          // Content List: Console or Network Waterfall
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF050505),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: _activeTab == 'console'
                  ? _buildConsoleList()
                  : _buildNetworkList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String id,
    required String label,
    required int count,
    int errorCount = 0,
    required IconData icon,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _activeTab = id;
          _searchController.clear();
          _searchQuery = '';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.cyan.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppTheme.cyan.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? AppTheme.cyan : AppTheme.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: errorCount > 0
                    ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: errorCount > 0 ? const Color(0xFFFF6B6B) : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsoleList() {
    if (_filteredLogs.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty
              ? 'No console events matching "$_searchQuery".'
              : 'No console events recorded yet.',
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
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
    );
  }

  Widget _buildNetworkList() {
    if (_filteredNetworkRequests.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty
              ? 'No requests matching "$_searchQuery".'
              : 'No network requests recorded yet.',
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredNetworkRequests.length,
      itemBuilder: (context, index) {
        final req = _filteredNetworkRequests[index];
        final statusColor = _getStatusColor(req.status);
        final durationColor = _getDurationColor(req.durationMs);

        return InkWell(
          onTap: () => _showRequestDetails(req),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Status code badge
                Container(
                  width: 38,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    req.status == 0 ? 'ERR' : '${req.status}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                // Method badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    req.method,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: Color(0xFFCCCCCC),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Path with query and host subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.pathWithQuery,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.white,
                        ),
                      ),
                      if (req.hostWithPort.isNotEmpty)
                        Text(
                          req.hostWithPort,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            fontFamily: 'monospace',
                            color: Color(0xFF666666),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Duration pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: durationColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${req.durationMs}ms',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      color: durationColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _activeTab == 'console'
        ? _selectedLogFilter == key
        : _selectedNetworkFilter == key;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (_activeTab == 'console') {
            _selectedLogFilter = key;
          } else {
            _selectedNetworkFilter = key;
          }
        });
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
