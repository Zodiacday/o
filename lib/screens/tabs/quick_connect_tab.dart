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
import '../../models/session_item.dart';
import '../../theme/app_theme.dart';

class DevPortPreset {
  final int port;
  final String framework;
  final String description;
  final IconData icon;
  final bool isHttps;
  final bool isCustom;

  const DevPortPreset({
    required this.port,
    required this.framework,
    required this.description,
    required this.icon,
    this.isHttps = false,
    this.isCustom = false,
  });

  DevPortPreset copyWith({
    int? port,
    String? framework,
    String? description,
    IconData? icon,
    bool? isHttps,
    bool? isCustom,
  }) {
    return DevPortPreset(
      port: port ?? this.port,
      framework: framework ?? this.framework,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isHttps: isHttps ?? this.isHttps,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
    'port': port,
    'framework': framework,
    'description': description,
    'isHttps': isHttps,
    'isCustom': isCustom,
  };

  factory DevPortPreset.fromJson(Map<String, dynamic> json) {
    final port = json['port'] as int? ?? 3000;
    final isHttps = json['isHttps'] as bool? ?? false;
    final isCustom = json['isCustom'] as bool? ?? true;
    final framework = json['framework'] as String?;
    final description = json['description'] as String?;

    final signature = DevPortPreset.fromPortAndSignature(
      port,
      fallbackTitle: framework,
      isHttps: isHttps,
      isCustom: isCustom,
    );

    return DevPortPreset(
      port: port,
      framework: (framework != null && framework.trim().isNotEmpty)
          ? framework
          : signature.framework,
      description: (description != null && description.trim().isNotEmpty)
          ? description
          : signature.description,
      icon: signature.icon,
      isHttps: isHttps,
      isCustom: isCustom,
    );
  }

  static DevPortPreset fromPortAndSignature(
    int port, {
    String? fallbackTitle,
    bool isHttps = false,
    bool isCustom = false,
  }) {
    switch (port) {
      case 5173:
        return DevPortPreset(
          port: port,
          framework: 'Vite / Astro',
          description: 'Vue, Svelte, React',
          icon: PhosphorIconsRegular.lightning,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 3000:
        return DevPortPreset(
          port: port,
          framework: 'Next.js',
          description: 'React, Remix, Node',
          icon: PhosphorIconsRegular.code,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 8080:
        return DevPortPreset(
          port: port,
          framework: 'Flutter Web',
          description: 'PreviewPort, Spring',
          icon: PhosphorIconsRegular.deviceMobile,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 8000:
        return DevPortPreset(
          port: port,
          framework: 'FastAPI / API',
          description: 'Python, Flask, Rails',
          icon: PhosphorIconsRegular.terminalWindow,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 4200:
        return DevPortPreset(
          port: port,
          framework: 'Angular',
          description: 'Angular CLI, RxJS',
          icon: PhosphorIconsRegular.browsers,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 8081:
        return DevPortPreset(
          port: port,
          framework: 'React Native',
          description: 'Metro Bundler',
          icon: PhosphorIconsRegular.deviceMobile,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 5000:
        return DevPortPreset(
          port: port,
          framework: 'Flask / API',
          description: 'Python Web API',
          icon: PhosphorIconsRegular.terminalWindow,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 1234:
        return DevPortPreset(
          port: port,
          framework: 'Parcel',
          description: 'Zero-config bundler',
          icon: PhosphorIconsRegular.package,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      case 8888:
        return DevPortPreset(
          port: port,
          framework: 'Jupyter / MAMP',
          description: 'Notebooks, PHP',
          icon: PhosphorIconsRegular.browsers,
          isHttps: isHttps,
          isCustom: isCustom,
        );
      default:
        return DevPortPreset(
          port: port,
          framework: (fallbackTitle != null && fallbackTitle.trim().isNotEmpty)
              ? fallbackTitle.trim()
              : 'Port $port',
          description: 'Local Dev Server',
          icon: PhosphorIconsRegular.terminalWindow,
          isHttps: isHttps,
          isCustom: isCustom,
        );
    }
  }
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
  static const String _kCustomPresetsPrefKey = 'quick_connect_custom_presets_v1';

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
      final interfaces =
          await NetworkInterface.list(type: InternetAddressType.IPv4);
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

  void _showSlotPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            decoration: BoxDecoration(
              color: const Color(0xFA0B0E17),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: const Color(0xFF1B2232), width: 0.9),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF243044),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customize Matrix Slots',
                      style: AppTypography.modalTitle(),
                    ),
                    if (_isCustomPinned)
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _resetToAutoAdaptive();
                        },
                        child: Text(
                          'Reset All to Auto',
                          style: AppTypography.monoData(
                            fontSize: 11,
                            color: AppTheme.cyan,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a slot to configure its port, framework signature, or protocol.',
                  style: AppTypography.subtitle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                ...List.generate(_presets.length, (i) {
                  final preset = _presets[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Bounceable(
                      scaleFactor: 0.98,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _showEditPresetDialog(i);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121724),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF1E283C),
                            width: 0.8,
                          ),
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
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: AppTypography.monoCounter(
                                    color: AppTheme.cyan,
                                  ).copyWith(fontSize: 14),
                                ),
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
                                        ':${preset.port}',
                                        style: AppTypography.monoData(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (preset.isHttps) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppTheme.cyan
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'SSL',
                                            style: AppTypography.monoData(
                                              fontSize: 8,
                                              color: AppTheme.cyan,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    preset.framework,
                                    style: AppTypography.subtitle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              PhosphorIconsRegular.pencilSimple,
                              size: 15,
                              color: AppTheme.cyan,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditPresetDialog(int slotIndex) {
    final currentPreset = _presets[slotIndex];
    final portController =
        TextEditingController(text: currentPreset.port.toString());
    final nameController =
        TextEditingController(text: currentPreset.framework);
    var isHttps = currentPreset.isHttps;
    var userModifiedName = false;

    // Quick-pick framework chips
    final quickFrameworks = [
      (port: 5173, label: 'Vite', icon: PhosphorIconsRegular.lightning),
      (port: 3000, label: 'Next.js', icon: PhosphorIconsRegular.code),
      (port: 4200, label: 'Angular', icon: PhosphorIconsRegular.browsers),
      (port: 8081, label: 'React Native', icon: PhosphorIconsRegular.deviceMobile),
      (port: 8000, label: 'FastAPI', icon: PhosphorIconsRegular.terminalWindow),
      (port: 5000, label: 'Flask', icon: PhosphorIconsRegular.terminalWindow),
      (port: 8080, label: 'Flutter Web', icon: PhosphorIconsRegular.deviceMobile),
      (port: 1234, label: 'Parcel', icon: PhosphorIconsRegular.package),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xEB121418),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0x3800E5FF),
                      width: 0.9,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2600E5FF),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.cyan.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    PhosphorIconsRegular.slidersHorizontal,
                                    size: 16,
                                    color: AppTheme.cyan,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Slot ${slotIndex + 1} Configuration',
                                  style: AppTypography.modalTitle(),
                                ),
                              ],
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: const Icon(
                                PhosphorIconsRegular.x,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customize port, framework signature, and protocol.',
                          style: AppTypography.subtitle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),

                        // Quick Pick Framework Chips
                        Text(
                          'QUICK POPULAR PRESETS',
                          style: AppTypography.monoData(
                            fontSize: 9,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: quickFrameworks.map((fw) {
                            final isCurrentPort =
                                portController.text.trim() == fw.port.toString();
                            return Bounceable(
                              scaleFactor: 0.95,
                              onTap: () {
                                setDialogState(() {
                                  portController.text = fw.port.toString();
                                  nameController.text = fw.label;
                                  userModifiedName = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentPort
                                      ? AppTheme.cyan.withValues(alpha: 0.15)
                                      : const Color(0xFF0C101A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCurrentPort
                                        ? AppTheme.cyan
                                        : const Color(0xFF1F283C),
                                    width: isCurrentPort ? 1.0 : 0.7,
                                  ),
                                ),
                                child: Text(
                                  ':${fw.port} ${fw.label}',
                                  style: AppTypography.monoData(
                                    fontSize: 10,
                                    color: isCurrentPort
                                        ? AppTheme.cyan
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Port Field
                        Text(
                          'PORT NUMBER',
                          style: AppTypography.monoData(
                            fontSize: 9.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: portController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(5),
                          ],
                          style: AppTypography.monoData(
                              fontSize: 15, color: Colors.white),
                          cursorColor: AppTheme.cyan,
                          onChanged: (val) {
                            final p = int.tryParse(val.trim());
                            if (p != null && !userModifiedName) {
                              final sig =
                                  DevPortPreset.fromPortAndSignature(p);
                              if (sig.framework != 'Port $p') {
                                setDialogState(() {
                                  nameController.text = sig.framework;
                                });
                              }
                            }
                          },
                          decoration: InputDecoration(
                            prefixText: ': ',
                            prefixStyle: AppTypography.monoData(
                              fontSize: 15,
                              color: AppTheme.cyan,
                            ),
                            hintText: '5173',
                            hintStyle: AppTypography.monoData(
                                color: AppTheme.textMuted),
                            filled: true,
                            fillColor: const Color(0xFF0C101A),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1B2232)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1B2232)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppTheme.cyan),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Framework Nickname
                        Text(
                          'FRAMEWORK / NICKNAME',
                          style: AppTypography.monoData(
                            fontSize: 9.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          onChanged: (_) => userModifiedName = true,
                          style: AppTypography.body(fontSize: 14),
                          cursorColor: AppTheme.cyan,
                          decoration: InputDecoration(
                            hintText: 'e.g. Vite, Next.js, Storefront',
                            hintStyle: AppTypography.body(
                                fontSize: 13, color: AppTheme.textMuted),
                            filled: true,
                            fillColor: const Color(0xFF0C101A),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1B2232)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFF1B2232)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: AppTheme.cyan),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Protocol Selector Pill
                        Text(
                          'PROTOCOL',
                          style: AppTypography.monoData(
                            fontSize: 9.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Bounceable(
                                scaleFactor: 0.97,
                                onTap: () =>
                                    setDialogState(() => isHttps = false),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !isHttps
                                        ? AppTheme.cyan.withValues(alpha: 0.15)
                                        : const Color(0xFF0C101A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: !isHttps
                                          ? AppTheme.cyan
                                          : const Color(0xFF1B2232),
                                      width: !isHttps ? 1.2 : 0.8,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'HTTP',
                                    style: AppTypography.monoData(
                                      fontSize: 12,
                                      color: !isHttps
                                          ? AppTheme.cyan
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Bounceable(
                                scaleFactor: 0.97,
                                onTap: () =>
                                    setDialogState(() => isHttps = true),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isHttps
                                        ? AppTheme.cyan.withValues(alpha: 0.15)
                                        : const Color(0xFF0C101A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isHttps
                                          ? AppTheme.cyan
                                          : const Color(0xFF1B2232),
                                      width: isHttps ? 1.2 : 0.8,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        PhosphorIconsRegular.lockKey,
                                        size: 13,
                                        color: isHttps
                                            ? AppTheme.cyan
                                            : AppTheme.textMuted,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'HTTPS (SSL)',
                                        style: AppTypography.monoData(
                                          fontSize: 12,
                                          color: isHttps
                                              ? AppTheme.cyan
                                              : AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Actions Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_isCustomPinned)
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _resetToAutoAdaptive();
                                },
                                icon: const Icon(
                                  PhosphorIconsRegular.arrowCounterClockwise,
                                  size: 14,
                                  color: AppTheme.textMuted,
                                ),
                                label: Text(
                                  'Reset to Auto',
                                  style: AppTypography.monoData(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text(
                                    'Cancel',
                                    style: AppTypography.button(
                                        color: AppTheme.textSecondary),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Bounceable(
                                  onTap: () {
                                    final p = int.tryParse(
                                        portController.text.trim());
                                    if (p == null || p < 1 || p > 65535) {
                                      return;
                                    }

                                    final nickname = nameController.text.trim();
                                    final sig =
                                        DevPortPreset.fromPortAndSignature(
                                      p,
                                      fallbackTitle: nickname,
                                      isHttps: isHttps,
                                      isCustom: true,
                                    );

                                    final updatedPreset = DevPortPreset(
                                      port: p,
                                      framework: nickname.isNotEmpty
                                          ? nickname
                                          : sig.framework,
                                      description: sig.description,
                                      icon: sig.icon,
                                      isHttps: isHttps,
                                      isCustom: true,
                                    );

                                    final updatedList =
                                        List<DevPortPreset>.from(_presets);
                                    updatedList[slotIndex] = updatedPreset;

                                    Navigator.of(ctx).pop();
                                    _saveCustomPresets(updatedList);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cyan,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x3D00E5FF),
                                          blurRadius: 10,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Save & Pin',
                                      style: AppTypography.button(
                                          color: Colors.black),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<SessionItem> get _filteredActivePrototypes {
    return widget.history.where((item) {
      final uri = Uri.tryParse(item.url);
      if (uri == null) return true;
      final itemHost = uri.host;
      final itemPort =
          uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
      final isMatchingPreset =
          _presets.any((p) => p.port == itemPort && itemHost == _targetHost);

      if (isMatchingPreset) {
        // Keep if session has custom paths, query params, or controlUrl
        if (uri.pathSegments.isNotEmpty ||
            uri.query.isNotEmpty ||
            item.controlUrl != null) {
          return true;
        }
        final matchingPreset = _presets.firstWhere((p) => p.port == itemPort);
        final defaultTitle =
            '${matchingPreset.framework} (${matchingPreset.port})';
        final isDefaultPresetTitle = item.title == defaultTitle ||
            item.title == matchingPreset.framework ||
            item.title == ':${matchingPreset.port}';
        if (isDefaultPresetTitle) {
          return false; // Redundant duplicate! Filter out.
        }
      }
      return true;
    }).take(3).toList();
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
                  Text(
                    'LOCAL DEV SERVERS',
                    style: AppTypography.sectionHud(),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    Text(
                      'TARGET WORKSTATION',
                      style: AppTypography.monoData(
                        fontSize: 9.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: _isHostReachable
                            ? AppTheme.statusGreen.withValues(alpha: 0.12)
                            : AppTheme.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _isHostReachable
                              ? AppTheme.statusGreen.withValues(alpha: 0.35)
                              : AppTheme.warning.withValues(alpha: 0.40),
                          width: 0.7,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _isHostReachable
                                  ? AppTheme.statusGreen
                                  : AppTheme.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isHostReachable ? 'REACHABLE' : 'UNREACHABLE',
                            style: AppTypography.monoData(
                              fontSize: 8.5,
                              color: _isHostReachable
                                  ? AppTheme.statusGreen
                                  : AppTheme.warning,
                            ),
                          ),
                        ],
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
                if (!_isHostReachable) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        PhosphorIconsRegular.warningCircle,
                        size: 11,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Host timed out. Ensure phone & PC are on the same Wi-Fi.',
                          style: AppTypography.monoData(
                            fontSize: 9.5,
                            color: AppTheme.warning,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
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
        widget.onLaunchApp(url,
            title: isTunnel ? 'Cloud Tunnel' : 'Clipboard Link');
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
                        isTunnel
                            ? 'TUNNEL DETECTED IN CLIPBOARD'
                            : 'URL IN CLIPBOARD',
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
        final scheme = preset.isHttps ? 'https' : 'http';
        final targetUrl = '$scheme://$_targetHost:${preset.port}';

        return Bounceable(
          scaleFactor: 0.96,
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onLaunchApp(
              targetUrl,
              title: '${preset.framework} (${preset.port})',
            );
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _showEditPresetDialog(index);
          },
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: isLive ? const Color(0xFF0E1422) : const Color(0xFF090C12),
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
                    Row(
                      children: [
                        Text(
                          ':${preset.port}',
                          style: AppTypography.monoCounter(
                            color: isLive ? AppTheme.cyan : Colors.white,
                          ).copyWith(fontSize: 17),
                        ),
                        if (preset.isHttps) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppTheme.cyan.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppTheme.cyan.withValues(alpha: 0.3),
                                width: 0.7,
                              ),
                            ),
                            child: Text(
                              'SSL',
                              style: AppTypography.monoData(
                                fontSize: 8,
                                color: AppTheme.cyan,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
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
                                  fontSize: 8.5,
                                  color: isLive
                                      ? AppTheme.statusGreen
                                      : const Color(0xFF718096),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 5),
                        // Explicit, visible, 1-tap edit trigger
                        Bounceable(
                          scaleFactor: 0.90,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _showEditPresetDialog(index);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF243044),
                                width: 0.7,
                              ),
                            ),
                            child: const Icon(
                              PhosphorIconsRegular.pencilSimple,
                              size: 11,
                              color: AppTheme.cyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.framework,
                      style: AppTypography.headline().copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset.description,
                      style: AppTypography.subtitle(fontSize: 10.5),
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

  IconData _resolvePrototypeIcon(SessionItem item) {
    if (item.controlUrl != null) return PhosphorIconsRegular.desktop;
    final uri = Uri.tryParse(item.url);
    if (uri == null) return PhosphorIconsRegular.browsers;

    final host = uri.host.toLowerCase();
    if (host.contains('trycloudflare') ||
        host.contains('ngrok') ||
        host.contains('loca.lt')) {
      return PhosphorIconsRegular.cloud;
    }

    if (uri.hasPort) {
      switch (uri.port) {
        case 5173:
          return PhosphorIconsRegular.lightning;
        case 3000:
          return PhosphorIconsRegular.code;
        case 4200:
          return PhosphorIconsRegular.browsers;
        case 8081:
        case 8080:
          return PhosphorIconsRegular.deviceMobile;
        case 8000:
        case 5000:
          return PhosphorIconsRegular.terminalWindow;
        case 1234:
          return PhosphorIconsRegular.package;
        case 8888:
          return PhosphorIconsRegular.browsers;
      }
    }
    return PhosphorIconsRegular.browsers;
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
              child: Icon(
                _resolvePrototypeIcon(item),
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
