import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:http/http.dart' as http;
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/nearby_preview.dart';
import '../../models/dev_port_preset.dart';
import '../../models/session_item.dart';
import '../../theme/app_theme.dart';

part 'quick_connect_tab_dialogs.dart';
part 'quick_connect_tab_sections.dart';

class QuickConnectTab extends StatefulWidget {
  final List<SessionItem> history;
  final List<NearbyPreview> nearbyPreviews;
  final void Function(String url, {String? title, String? controlUrl})
  onLaunchApp;
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
  static const String _kCustomPresetsPrefKey =
      'quick_connect_custom_presets_v1';

  static const List<DevPortPreset> defaultPresets = [
    DevPortPreset(
      port: 5173,
      framework: 'Vite / Astro',
      description: 'Vue, Svelte, React',
      icon: PhosphorIconsRegular.lightning,
    ),
    DevPortPreset(
      port: 3000,
      framework: 'Next.js',
      description: 'React, Remix, Node',
      icon: PhosphorIconsRegular.code,
    ),
    DevPortPreset(
      port: 8080,
      framework: 'Flutter Web',
      description: 'PreviewPort, Spring',
      icon: PhosphorIconsRegular.deviceMobile,
    ),
    DevPortPreset(
      port: 8000,
      framework: 'FastAPI / API',
      description: 'Python, Flask, Rails',
      icon: PhosphorIconsRegular.terminalWindow,
    ),
  ];

  String _targetHost = '192.168.1.100';
  String? _detectedClipboardUrl;
  bool _isProbing = false;
  bool _isCustomPinned = false;
  bool _isHostReachable = true;

  final Map<int, bool> _livePorts = {};
  late List<DevPortPreset> _presets;

  @override
  void initState() {
    super.initState();
    _presets = List.from(defaultPresets);
    WidgetsBinding.instance.addObserver(this);
    _initializePresets();
    _initializeTargetHost();
    _checkClipboard();
  }

  @override
  void didUpdateWidget(QuickConnectTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isCustomPinned && oldWidget.history != widget.history) {
      _computeAdaptivePresets();
      _probeAllPorts();
    }
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

  Future<void> _initializePresets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCustomPresetsPrefKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final loaded = decoded
            .map((e) => DevPortPreset.fromJson(e as Map<String, dynamic>))
            .toList();
        if (loaded.length == 4) {
          if (mounted) {
            setState(() {
              _presets = loaded;
              _isCustomPinned = true;
            });
          }
          return;
        }
      } catch (_) {}
    }

    _computeAdaptivePresets();
  }

  void _computeAdaptivePresets() {
    final portCounts = <int, int>{};
    final portLatestTime = <int, DateTime>{};
    final portFallbackTitle = <int, String>{};
    final portIsHttps = <int, bool>{};

    for (final item in widget.history) {
      final uri = Uri.tryParse(item.url);
      if (uri != null && uri.hasPort && uri.port > 0) {
        final port = uri.port;
        portCounts[port] = (portCounts[port] ?? 0) + 1;
        if (!portLatestTime.containsKey(port) ||
            item.timestamp.isAfter(portLatestTime[port]!)) {
          portLatestTime[port] = item.timestamp;
        }
        if (!portFallbackTitle.containsKey(port) &&
            item.title.isNotEmpty &&
            !item.title.contains(':')) {
          portFallbackTitle[port] = item.title;
        }
        if (uri.scheme == 'https') {
          portIsHttps[port] = true;
        }
      }
    }

    final discoveredPorts = portCounts.keys.toList()
      ..sort((a, b) {
        final countComp = portCounts[b]!.compareTo(portCounts[a]!);
        if (countComp != 0) return countComp;
        return portLatestTime[b]!.compareTo(portLatestTime[a]!);
      });

    final List<DevPortPreset> adaptive = [];
    for (final port in discoveredPorts.take(4)) {
      adaptive.add(
        DevPortPreset.fromPortAndSignature(
          port,
          fallbackTitle: portFallbackTitle[port],
          isHttps: portIsHttps[port] ?? false,
          isCustom: false,
        ),
      );
    }

    for (final defaultPreset in defaultPresets) {
      if (adaptive.length >= 4) break;
      if (!adaptive.any((p) => p.port == defaultPreset.port)) {
        adaptive.add(defaultPreset);
      }
    }

    if (mounted) {
      setState(() {
        _presets = adaptive;
        _isCustomPinned = false;
      });
    }
  }

  Future<void> _saveCustomPresets(List<DevPortPreset> presets) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(presets.map((p) => p.toJson()).toList());
    await prefs.setString(_kCustomPresetsPrefKey, jsonStr);

    if (mounted) {
      setState(() {
        _presets = presets;
        _isCustomPinned = true;
      });
      _probeAllPorts();
    }
  }

  Future<void> _resetToAutoAdaptive() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCustomPresetsPrefKey);

    if (mounted) {
      setState(() => _isCustomPinned = false);
      _computeAdaptivePresets();
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
      if (uri != null &&
          uri.host.isNotEmpty &&
          uri.host != 'localhost' &&
          mounted) {
        setState(() => _targetHost = uri.host);
      }
    } else {
      await _detectSubnetHost();
    }

    _probeAllPorts();
  }

  Future<void> _detectSubnetHost() async {
    if (kIsWeb) return;
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && !addr.isLinkLocal) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final guessed = '${parts[0]}.${parts[1]}.${parts[2]}.100';
              if (mounted) setState(() => _targetHost = guessed);
              return;
            }
          }
        }
      }
    } catch (_) {}
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
    var hostContacted = false;

    try {
      await Future.wait(
        _presets.map((preset) async {
          final scheme = preset.isHttps ? 'https' : 'http';
          final url = Uri.parse('$scheme://$_targetHost:${preset.port}');
          var isLive = false;
          try {
            final response = await client
                .head(url)
                .timeout(const Duration(milliseconds: 450));
            isLive = response.statusCode > 0;
            if (isLive) {
              hostContacted = true;
            }
          } catch (e) {
            if (e is SocketException) {
              // TCP RST / Refused indicates host is alive on local network!
              final msg = e.message.toLowerCase();
              if (msg.contains('refused') ||
                  e.osError?.errorCode == 111 ||
                  e.osError?.errorCode == 10061) {
                hostContacted = true;
              }
              isLive = false;
            } else if (e is TimeoutException) {
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

      // If no preset port responded, attempt a quick ping on default web ports
      if (!hostContacted && !kIsWeb) {
        try {
          final socket = await Socket.connect(
            _targetHost,
            80,
            timeout: const Duration(milliseconds: 350),
          );
          socket.destroy();
          hostContacted = true;
        } catch (e) {
          if (e is SocketException) {
            final msg = e.message.toLowerCase();
            if (msg.contains('refused') ||
                e.osError?.errorCode == 111 ||
                e.osError?.errorCode == 10061) {
              hostContacted = true;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _isHostReachable = hostContacted;
        });
      }
    } finally {
      client.close();
      if (mounted) setState(() => _isProbing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePrototypes = _filteredActivePrototypes;

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
          // 1. Workstation Target HUD Bar (with Dynamic Reachability Beacon)
          _buildWorkstationHud(),
          const SizedBox(height: 16),

          // 2. Smart Clipboard Strip (Dynamic)
          if (_detectedClipboardUrl != null) ...[
            _buildClipboardBanner(),
            const SizedBox(height: 20),
          ],

          // 3. Section Title: Live Local Servers with Mode Badge + Visible Edit Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('LOCAL DEV SERVERS', style: AppTypography.sectionHud()),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _isCustomPinned
                          ? AppTheme.cyan.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _isCustomPinned
                            ? AppTheme.cyan.withValues(alpha: 0.3)
                            : const Color(0xFF1B2232),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      _isCustomPinned ? 'PINNED' : 'AUTO',
                      style: AppTypography.monoData(
                        fontSize: 9,
                        color: _isCustomPinned
                            ? AppTheme.cyan
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Dedicated Visible Edit Action
                  Bounceable(
                    scaleFactor: 0.95,
                    onTap: _showSlotPickerSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141B28),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF243044),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            PhosphorIconsRegular.slidersHorizontal,
                            size: 11,
                            color: AppTheme.cyan,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Edit Slots',
                            style: AppTypography.monoData(
                              fontSize: 10,
                              color: AppTheme.cyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isCustomPinned)
                    Bounceable(
                      scaleFactor: 0.95,
                      onTap: _resetToAutoAdaptive,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          'Reset',
                          style: AppTypography.monoData(
                            fontSize: 10.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
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
                    _isProbing ? 'Probing…' : 'Tap or Edit',
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

          // 4. Live Port Matrix (2x2 Hardware Tiles with Direct Edit Icons)
          _buildPortMatrix(),
          const SizedBox(height: 28),

          // 5. Active Prototypes Today
          if (activePrototypes.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'ACTIVE PROTOTYPES TODAY',
                  style: AppTypography.sectionHud(),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF1B2232),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${activePrototypes.length}',
                    style: AppTypography.monoData(
                      fontSize: 9,
                      color: AppTheme.cyan,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...activePrototypes.map(_buildActivePrototypeRow),
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
}
