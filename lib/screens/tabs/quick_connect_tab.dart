import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:http/http.dart' as http;
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/nearby_preview.dart';
import '../../models/session_item.dart';
import '../../theme/app_theme.dart';

class DevPortPreset {
  final int port;
  final String framework;
  final String description;
  final IconData icon;

  const DevPortPreset({
    required this.port,
    required this.framework,
    required this.description,
    required this.icon,
  });
}

class QuickConnectTab extends StatefulWidget {
  final List<SessionItem> history;
  final List<NearbyPreview> nearbyPreviews;
  final void Function(String url, {String? title, String? controlUrl}) onLaunchApp;
  final VoidCallback onOpenHistory;
  final VoidCallback? onRefresh;

  const QuickConnectTab({
    super.key,
    required this.history,
    required this.nearbyPreviews,
    required this.onLaunchApp,
    required this.onOpenHistory,
    this.onRefresh,
  });

  @override
  State<QuickConnectTab> createState() => _QuickConnectTabState();
}

class _QuickConnectTabState extends State<QuickConnectTab>
    with WidgetsBindingObserver {
  static const String _kHostPrefKey = 'quick_connect_target_host';

  String _targetHost = '192.168.1.100';
  String? _detectedClipboardUrl;
  bool _isProbing = false;

  final Map<int, bool> _livePorts = {};

  final List<DevPortPreset> _presets = [
    const DevPortPreset(
      port: 5173,
      framework: 'Vite / Astro',
      description: 'Vue, Svelte, React',
      icon: PhosphorIconsRegular.lightning,
    ),
    const DevPortPreset(
      port: 3000,
      framework: 'Next.js',
      description: 'React, Remix, Node',
      icon: PhosphorIconsRegular.code,
    ),
    const DevPortPreset(
      port: 8080,
      framework: 'Flutter Web',
      description: 'PreviewPort, Spring',
      icon: PhosphorIconsRegular.deviceMobile,
    ),
    const DevPortPreset(
      port: 8000,
      framework: 'FastAPI / API',
      description: 'Python, Flask, Rails',
      icon: PhosphorIconsRegular.terminalWindow,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTargetHost();
    _checkClipboard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
      _probeAllPorts();
    }
  }

  Future<void> _initializeTargetHost() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHost = prefs.getString(_kHostPrefKey);

    if (savedHost != null && savedHost.isNotEmpty) {
      if (mounted) setState(() => _targetHost = savedHost);
    } else if (widget.nearbyPreviews.isNotEmpty) {
      final host = widget.nearbyPreviews.first.host;
      if (host.isNotEmpty && mounted) {
        setState(() => _targetHost = host);
      }
    } else if (widget.history.isNotEmpty) {
      final uri = Uri.tryParse(widget.history.first.url);
      if (uri != null && uri.host.isNotEmpty && mounted) {
        setState(() => _targetHost = uri.host);
      }
    }

    _probeAllPorts();
  }

  Future<void> _setTargetHost(String host) async {
    final clean = host.trim();
    if (clean.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHostPrefKey, clean);

    if (mounted) {
      setState(() => _targetHost = clean);
      _probeAllPorts();
    }
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';

      if (text.startsWith('http://') ||
          text.startsWith('https://') ||
          text.contains('.trycloudflare.com') ||
          text.contains('.ngrok') ||
          text.startsWith('localhost:')) {
        final resolved = text.startsWith('http') ? text : 'http://$text';
        if (mounted && _detectedClipboardUrl != resolved) {
          setState(() => _detectedClipboardUrl = resolved);
        }
      } else {
        if (mounted && _detectedClipboardUrl != null) {
          setState(() => _detectedClipboardUrl = null);
        }
      }
    } catch (_) {}
  }

  Future<void> _probeAllPorts() async {
    if (_isProbing) return;
    if (!mounted) return;

    setState(() => _isProbing = true);

    final client = http.Client();
    try {
      await Future.wait(
        _presets.map((preset) async {
          final url = Uri.parse('http://$_targetHost:${preset.port}');
          var isLive = false;
          try {
            final response = await client
                .head(url)
                .timeout(const Duration(milliseconds: 450));
            isLive = response.statusCode > 0;
          } catch (e) {
            if (e is SocketException || e is TimeoutException) {
              isLive = false;
            }
          }

          if (mounted) {
            setState(() {
              _livePorts[preset.port] = isLive;
            });
          }
        }),
      );
    } finally {
      client.close();
      if (mounted) setState(() => _isProbing = false);
    }
  }

  void _showEditHostDialog() {
    final controller = TextEditingController(text: _targetHost);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: Text(
          'Target Workstation IP',
          style: AppTypography.modalTitle(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your computer\'s local Wi-Fi or LAN IP address.',
              style: AppTypography.subtitle(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: AppTypography.monoData(fontSize: 14, color: Colors.white),
              cursorColor: AppTheme.cyan,
              decoration: InputDecoration(
                hintText: '192.168.1.100',
                hintStyle: AppTypography.monoData(color: AppTheme.textMuted),
                filled: true,
                fillColor: const Color(0xFF0C101A),
                prefixIcon: const Icon(
                  PhosphorIconsRegular.desktop,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.cyan),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.button(color: AppTheme.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _setTargetHost(controller.text);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.cyan,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save Host'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await _checkClipboard();
        await _probeAllPorts();
        widget.onRefresh?.call();
      },
      color: AppTheme.cyan,
      backgroundColor: const Color(0xFF141414),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
        children: [
          // 1. Workstation Target HUD Bar
          _buildWorkstationHud(),
          const SizedBox(height: 16),

          // 2. Smart Clipboard Strip (Dynamic)
          if (_detectedClipboardUrl != null) ...[
            _buildClipboardBanner(),
            const SizedBox(height: 20),
          ],

          // 3. Section Title: Live Local Servers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOCAL DEV SERVERS',
                style: AppTypography.sectionHud(),
              ),
              Row(
                children: [
                  if (_isProbing)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      child: const CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppTheme.cyan,
                      ),
                    ),
                  Text(
                    _isProbing ? 'Probing…' : 'Tap to Launch',
                    style: AppTypography.monoData(
                      fontSize: 10.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4. Live Port Matrix (2x2 Hardware Tiles)
          _buildPortMatrix(),
          const SizedBox(height: 28),

          // 5. Active Prototypes Today
          if (widget.history.isNotEmpty) ...[
            Text(
              'ACTIVE PROTOTYPES TODAY',
              style: AppTypography.sectionHud(),
            ),
            const SizedBox(height: 12),
            ...widget.history.take(3).map(_buildActivePrototypeRow),
            const SizedBox(height: 24),
          ],

          // 6. Direct Link to History in Settings
          Center(
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                widget.onOpenHistory();
              },
              icon: const Icon(
                PhosphorIconsRegular.clock,
                size: 14,
                color: AppTheme.textMuted,
              ),
              label: Text(
                'Looking for older sessions? Open History in Settings →',
                style: AppTypography.monoData(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkstationHud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E17),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B2232), width: 0.9),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              PhosphorIconsRegular.desktop,
              size: 16,
              color: AppTheme.cyan,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.statusGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TARGET WORKSTATION',
                      style: AppTypography.monoData(
                        fontSize: 9.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _targetHost,
                  style: AppTypography.monoData(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Bounceable(
            scaleFactor: 0.95,
            onTap: _showEditHostDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF141B28),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF243044)),
              ),
              child: Row(
                children: [
                  const Icon(
                    PhosphorIconsRegular.pencilSimple,
                    size: 12,
                    color: AppTheme.cyan,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Change IP',
                    style: AppTypography.button(
                      fontSize: 11,
                      color: AppTheme.cyan,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClipboardBanner() {
    final url = _detectedClipboardUrl!;
    final isTunnel = url.contains('trycloudflare.com') || url.contains('ngrok');

    return Bounceable(
      scaleFactor: 0.98,
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onLaunchApp(url, title: isTunnel ? 'Cloud Tunnel' : 'Clipboard Link');
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1524),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.cyan.withValues(alpha: 0.35),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.cyan.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.cyan.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                PhosphorIconsRegular.clipboardText,
                size: 18,
                color: AppTheme.cyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isTunnel ? 'TUNNEL DETECTED IN CLIPBOARD' : 'URL IN CLIPBOARD',
                        style: AppTypography.monoData(
                          fontSize: 9.5,
                          color: AppTheme.cyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.monoData(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.cyan,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Open ⚡',
                style: AppTypography.button(
                  fontSize: 11.5,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortMatrix() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.32,
      ),
      itemCount: _presets.length,
      itemBuilder: (context, index) {
        final preset = _presets[index];
        final isLive = _livePorts[preset.port] ?? false;
        final targetUrl = 'http://$_targetHost:${preset.port}';

        return Bounceable(
          scaleFactor: 0.96,
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onLaunchApp(
              targetUrl,
              title: '${preset.framework} (${preset.port})',
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isLive
                  ? const Color(0xFF0E1422)
                  : const Color(0xFF090C12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLive
                    ? AppTheme.cyan.withValues(alpha: 0.40)
                    : const Color(0xFF1B2232),
                width: 0.9,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ':${preset.port}',
                      style: AppTypography.monoCounter(
                        color: isLive ? AppTheme.cyan : Colors.white,
                      ).copyWith(fontSize: 18),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isLive
                            ? AppTheme.statusGreen.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isLive
                                  ? AppTheme.statusGreen
                                  : const Color(0xFF4A5568),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLive ? 'LIVE' : 'IDLE',
                            style: AppTypography.monoData(
                              fontSize: 9,
                              color: isLive
                                  ? AppTheme.statusGreen
                                  : const Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.framework,
                      style: AppTypography.headline().copyWith(fontSize: 13.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset.description,
                      style: AppTypography.subtitle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivePrototypeRow(SessionItem item) {
    return Bounceable(
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1B2232), width: 0.9),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1B2232), width: 0.8),
              ),
              child: const Icon(
                PhosphorIconsRegular.browsers,
                size: 16,
                color: AppTheme.cyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.headline().copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.displayUrl} · ${item.timeAgo}',
                    style: AppTypography.monoData(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              PhosphorIconsRegular.caretRight,
              size: 14,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
