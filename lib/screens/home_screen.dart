import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../models/session_item.dart';
import '../models/camera_capture_result.dart';
import '../models/preview_connection.dart';
import '../models/nearby_preview.dart';
import '../services/history_service.dart';
import '../services/native_camera_service.dart';
import '../services/nearby_preview_discovery_service.dart';
import '../widgets/animated_grid_pattern.dart';
import '../widgets/app_toast.dart';
import '../widgets/floating_navbar.dart';
import '../widgets/manual_url_modal.dart';
import '../widgets/rename_dialog.dart';
import 'app_viewer_screen.dart';
import 'settings_screen.dart';
import 'tabs/quick_connect_tab.dart';
import 'tabs/scans_tab.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentNavIndex = 0;
  List<SessionItem> _history = [];
  Uint8List? _capturedPhotoBytes;
  bool _isLoading = true;
  bool _isOpeningScanner = false;
  late final ScrollController _scanScrollController;
  late final NearbyPreviewDiscoveryService _nearbyDiscovery;
  List<NearbyPreview> _nearbyPreviews = const [];
  bool _appIsActive = true;
  static final List<List<int>> _gridSquares = [
    [1, 2], [3, 5], [7, 2], [8, 3], [10, 4],
    [2, 7], [4, 9], [6, 12], [8, 14], [3, 15],
    [11, 2], [12, 5], [14, 8], [9, 10], [5, 13],
    [7, 16], [2, 18], [10, 19], [4, 20], [8, 22],
  ];

  int get _safeNavIndex {
    if (_currentNavIndex < 0 ||
        _currentNavIndex >= FloatingNavBar.navItems.length) {
      return 0;
    }
    return _currentNavIndex;
  }

  void _selectNavIndex(int index) {
    if (index < 0 || index >= FloatingNavBar.navItems.length) return;
    if (_currentNavIndex == index) return;
    setState(() => _currentNavIndex = index);
    unawaited(_syncNearbyDiscovery());
  }

  @override
  void initState() {
    super.initState();
    _scanScrollController = ScrollController();
    _nearbyDiscovery = NearbyPreviewDiscoveryService(
      onChanged: (previews) {
        if (mounted) setState(() => _nearbyPreviews = previews);
      },
      onError: (_) {},
    );
    WidgetsBinding.instance.addObserver(this);
    _loadHistory();
    unawaited(_syncNearbyDiscovery());
  }

  Future<void> _syncNearbyDiscovery() async {
    if (kIsWeb || !_appIsActive || _safeNavIndex != 0) {
      await _nearbyDiscovery.stop();
      return;
    }
    await _nearbyDiscovery.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsActive = state == AppLifecycleState.resumed;
    if (_appIsActive) {
      _loadHistory();
      unawaited(_restartNearbyDiscovery());
    } else {
      unawaited(_syncNearbyDiscovery());
    }
  }

  Future<void> _restartNearbyDiscovery() async {
    await _nearbyDiscovery.stop();
    await _syncNearbyDiscovery();
  }

  Future<void> _loadHistory() async {
    final list = await HistoryService.getHistory();
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _openScanner() async {
    if (_isOpeningScanner) return;

    setState(() => _isOpeningScanner = true);
    try {
      final capture = await NativeCameraService.scanWithNativeCamera(context);

      if (!mounted || capture == null) return;

      if (capture is QrCameraCapture) {
        await _launchApp(
          capture.connection.url,
          title: capture.connection.projectName,
          controlUrl: capture.connection.controlUrl,
        );
      } else if (capture is PhotoCameraCapture) {
        final bytes = await capture.file.readAsBytes();
        if (mounted) setState(() => _capturedPhotoBytes = bytes);
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningScanner = false);
      }
    }
  }

  void _clearCapturedPhoto() {
    setState(() => _capturedPhotoBytes = null);
  }

  void _copyCliCommand() {
    Clipboard.setData(const ClipboardData(text: 'pp start'));
    AppToast.success(
      context,
      title: 'Command Copied',
      description: 'Run it in your Flutter project root to generate a QR code',
    );
  }

  Future<void> _launchApp(
    String url, {
    String? title,
    String? controlUrl,
  }) async {
    await HistoryService.saveSession(url, title: title, controlUrl: controlUrl);
    await _loadHistory();

    if (!mounted) return;
    await _nearbyDiscovery.stop();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AppViewerScreen(url: url, title: title, controlUrl: controlUrl),
      ),
    );

    _loadHistory();
    unawaited(_syncNearbyDiscovery());
  }

  Future<void> _openNearbyPreview(NearbyPreview preview) async {
    final uri = Uri.tryParse(preview.url);
    if (uri == null || uri.host.isEmpty) return;

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 2));
      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw StateError('Preview returned HTTP ${response.statusCode}');
      }
      await _launchApp(
        preview.url,
        title: preview.projectName,
        controlUrl: preview.controlUrl,
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.warning(
        context,
        title: 'Preview unavailable',
        description:
            '${preview.projectName} is no longer reachable on this network.',
      );
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();

    final connection = PreviewConnection.tryParse(text ?? '');
    if (connection != null) {
      HapticFeedback.mediumImpact();
      _launchApp(
        connection.url,
        title: connection.projectName,
        controlUrl: connection.controlUrl,
      );
    } else {
      if (mounted) {
        AppToast.warning(
          context,
          title: text != null && text.isNotEmpty
              ? 'Invalid Web URL'
              : 'Clipboard is Empty',
          description: text != null && text.isNotEmpty
              ? 'Clipboard does not contain a valid http/https link'
              : 'Copy a URL from your terminal or browser first',
        );
      }
    }
  }

  void _showManualUrlModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF000000),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ManualUrlModal(onConnect: _launchApp),
    );
  }

  void _showRenameDialog(SessionItem item) {
    showDialog(
      context: context,
      builder: (ctx) => RenameDialog(
        item: item,
        onSaved: (newName) async {
          await HistoryService.updateTitle(item.id, newName);
          _loadHistory();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // FlutterFX AnimatedGridPattern from flutterfx/flutterfx_widgets (half opacity)
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRect(
                child: Transform.translate(
                  offset: const Offset(0, -100),
                  child: Opacity(
                    opacity: 0.5,
                    child: AnimatedGridPattern(
                      squares: _gridSquares,
                      gridSize: 30,
                      skewAngle: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Floating brand lockup and full-height scrolling tab content.
          // The tab content extends from top: 0 so cards glide smoothly
          // underneath the floating brand header without clipping.
          SafeArea(
            child: Stack(
              children: [
                // 1. Tab Content Stack
                Positioned.fill(
                  child: IndexedStack(
                    index: _safeNavIndex,
                    children: [
                      ScansTab(
                        scrollController: _scanScrollController,
                        history: _history,
                        isLoading: _isLoading,
                        onOpenScanner: _openScanner,
                        onPasteUrl: _pasteFromClipboard,
                        onEnterUrl: _showManualUrlModal,
                        onCopyCommand: _copyCliCommand,
                        isScannerBusy: _isOpeningScanner,
                        onLaunchApp: _launchApp,
                        onLongPressItem: _showRenameDialog,
                        capturedPhotoBytes: _capturedPhotoBytes,
                        onDismissCapturedPhoto: _clearCapturedPhoto,
                        nearbyPreviews: _nearbyPreviews,
                        onOpenNearbyPreview: _openNearbyPreview,
                        onRefresh: () async {
                          await _loadHistory();
                          await _restartNearbyDiscovery();
                        },
                      ),
                      QuickConnectTab(
                        history: _history,
                        nearbyPreviews: _nearbyPreviews,
                        onLaunchApp: _launchApp,
                        onOpenHistory: () => setState(() => _currentNavIndex = 2),
                        onRefresh: () async {
                          await _loadHistory();
                          await _restartNearbyDiscovery();
                        },
                      ),
                      SettingsScreen(onLaunchApp: _launchApp),
                    ],
                  ),
                ),

                // 2. Floating brand lockup positioned on top of scrolling content.
                // Smoothly fades out when navigating to History or Settings so their
                // headline titles remain unobstructed and prominent.
                Positioned(
                  top: 12,
                  left: 22,
                  child: AnimatedOpacity(
                    opacity: _safeNavIndex == 0 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: IgnorePointer(
                      ignoring: _safeNavIndex != 0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/previewport-logo-transparent.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                          const SizedBox(width: 10),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Preview',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Port',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.cyan,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Real floating iOS glass pill navbar hovering over bottom content.
          // Suspended gracefully above the home indicator with side margins,
          // allowing the background grid and preview cards to blur behind it.
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom > 0
                ? MediaQuery.paddingOf(context).bottom + 6
                : 18,
            left: 20,
            right: 20,
            child: FloatingNavBar(
              currentIndex: _safeNavIndex,
              onTabSelected: _selectNavIndex,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanScrollController.dispose();
    unawaited(_nearbyDiscovery.dispose());
    super.dispose();
  }
}
