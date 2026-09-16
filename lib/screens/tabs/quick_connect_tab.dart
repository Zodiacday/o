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
  static const String _kPinnedSlotsPrefKey = 'quick_connect_pinned_slots_v2';

  String _targetHost = '192.168.1.100';
  String? _detectedClipboardUrl;
  bool _isProbing = false;
  bool _isHostReachable = true;

  final Map<int, bool> _livePorts = {};
  final Map<int, DevPortPreset> _pinnedSlots = {};
  late List<DevPortPreset?> _slots;

  bool get _hasPinnedSlots => _pinnedSlots.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _slots = List<DevPortPreset?>.filled(4, null);
    WidgetsBinding.instance.addObserver(this);
    _initializeSlots();
    _initializeTargetHost();
    _checkClipboard();
  }

  @override
  void didUpdateWidget(QuickConnectTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.history != widget.history) {
      _computeSlots();
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

  Future<void> _initializeSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPinnedSlotsPrefKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _pinnedSlots.clear();
        decoded.forEach((key, value) {
          final idx = int.tryParse(key);
          if (idx != null && idx >= 0 && idx < 4) {
            _pinnedSlots[idx] = DevPortPreset.fromJson(
              value as Map<String, dynamic>,
            );
          }
        });
      } catch (_) {}
    } else {
      // Backwards compatibility: check v1 format if v2 is not yet initialized
      final rawV1 = prefs.getString('quick_connect_custom_presets_v1');
      if (rawV1 != null && rawV1.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawV1) as List<dynamic>;
          _pinnedSlots.clear();
          for (var i = 0; i < decoded.length && i < 4; i++) {
            final p = DevPortPreset.fromJson(
              decoded[i] as Map<String, dynamic>,
            );
            if (p.isCustom) {
              _pinnedSlots[i] = p;
            }
          }
        } catch (_) {}
      }
    }

    _computeSlots();
  }

  void _computeSlots() {
    final slots = List<DevPortPreset?>.filled(4, null);
    final pinnedPorts = <int>{};

    // 1. Assign permanently pinned user slots
    for (var i = 0; i < 4; i++) {
      if (_pinnedSlots.containsKey(i)) {
        slots[i] = _pinnedSlots[i];
        pinnedPorts.add(_pinnedSlots[i]!.port);
      }
    }

    // 2. Discover and rank ports from connection history
    final portCounts = <int, int>{};
    final portLatestTime = <int, DateTime>{};
    final portFallbackTitle = <int, String>{};
    final portIsHttps = <int, bool>{};

    for (final item in widget.history) {
      final uri = Uri.tryParse(item.url);
      if (uri != null && uri.hasPort && uri.port > 0) {
        final port = uri.port;
        if (pinnedPorts.contains(port)) continue; // Don't duplicate pinned ports

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

    // 3. Fill available slots with auto-learned ports
    var learnedIdx = 0;
    for (var i = 0; i < 4; i++) {
      if (slots[i] == null && learnedIdx < discoveredPorts.length) {
        final port = discoveredPorts[learnedIdx++];
        slots[i] = DevPortPreset.fromPortAndSignature(
          port,
          fallbackTitle: portFallbackTitle[port],
          isHttps: portIsHttps[port] ?? false,
          isCustom: false,
        );
      }
    }

    // Slots without pinned or learned ports stay null (EMPTY)

    if (mounted) {
      setState(() {
        _slots = slots;
      });
    }
  }

  Future<void> _pinSlot(int index, DevPortPreset preset) async {
    final updated = preset.copyWith(isCustom: true);
    _pinnedSlots[index] = updated;
    await _persistPinnedSlots();
    _computeSlots();
    _probeAllPorts();
  }

  Future<void> _unpinSlot(int index) async {
    _pinnedSlots.remove(index);
    await _persistPinnedSlots();
    _computeSlots();
    _probeAllPorts();
  }

  Future<void> _persistPinnedSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final mapToSave = <String, dynamic>{};
    _pinnedSlots.forEach((key, val) {
      mapToSave[key.toString()] = val.toJson();
    });
    await prefs.setString(_kPinnedSlotsPrefKey, jsonEncode(mapToSave));
  }

  Future<void> _resetAllSlots() async {
    HapticFeedback.lightImpact();
    _pinnedSlots.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPinnedSlotsPrefKey);
    await prefs.remove('quick_connect_custom_presets_v1');

    if (mounted) {
      _computeSlots();
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
      final activePresets = _slots.whereType<DevPortPreset>().toList();
      if (activePresets.isNotEmpty) {
        await Future.wait(
          activePresets.map((preset) async {
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
      }

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
          // 3. Section Title: Clean Header without Instructional Clutter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('DEV PORTS', style: AppTypography.sectionHud()),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _hasPinnedSlots
                          ? AppTheme.cyan.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _hasPinnedSlots
                            ? AppTheme.cyan.withValues(alpha: 0.3)
                            : const Color(0xFF1B2232),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      _hasPinnedSlots ? 'PINNED' : 'AUTO',
                      style: AppTypography.monoData(
                        fontSize: 9,
                        color: _hasPinnedSlots
                            ? AppTheme.cyan
                            : AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (_isProbing)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      child: const CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppTheme.cyan,
                      ),
                    ),
                  if (_hasPinnedSlots)
                    Bounceable(
                      scaleFactor: 0.95,
                      onTap: _resetAllSlots,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'Reset',
                          style: AppTypography.monoData(
                            fontSize: 10.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  Bounceable(
                    scaleFactor: 0.95,
                    onTap: _showSlotPickerSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                'Open History in Settings →',
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
