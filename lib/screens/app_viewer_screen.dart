import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';
import '../services/shake_detector.dart';
import '../services/preview_diagnostics_channel.dart';
import '../services/native_bridge.dart';
import '../models/preview_diagnostic.dart';
import '../widgets/preview_loading_progress.dart';
import '../widgets/preview_error_sheet.dart';
import '../widgets/location_mock_sheet.dart';
import '../widgets/viewport_switcher_sheet.dart';
import '../widgets/floating_ghost_capsule.dart';
import '../widgets/mini_terminal_drawer.dart';
import '../widgets/bug_annotator_modal.dart';

class AppViewerScreen extends StatefulWidget {
  final String url;
  final String? title;
  final String? controlUrl;

  const AppViewerScreen({
    super.key,
    required this.url,
    this.title,
    this.controlUrl,
  });

  @override
  State<AppViewerScreen> createState() => _AppViewerScreenState();
}

class _AppViewerScreenState extends State<AppViewerScreen>
    with WidgetsBindingObserver {
  static const _minimumLoadingDisplay = Duration(milliseconds: 900);

  late final WebViewController _controller;
  late final NativeBridgeHandler _nativeBridge;
  final GlobalKey _viewportKey = GlobalKey();

  String? _dynamicTitle;
  int _loadingProgress = 0;
  bool _isPageReady = false;
  bool _hasError = false;
  PreviewDiagnostic? _diagnostic;
  bool _errorDismissed = false;
  bool _isMenuOpen = false;
  bool _useSafeArea = false;
  bool _showFloatingCapsule = true;
  late final ShakeDetector _shakeDetector;
  PreviewDiagnosticsChannel? _diagnosticsChannel;
  Timer? _loadingCompletionTimer;
  DateTime? _loadingStartedAt;

  // PreviewPort 2.0 Simulation & Log State
  String _networkCondition = 'normal'; // 'normal' | '3g' | 'offline'
  MockLocationPreset _selectedLocation = defaultLocationPresets.first;
  SimulatedDeviceProfile _selectedDevice = defaultDeviceProfiles.first;
  final List<TerminalLogEntry> _terminalLogs = [];
  bool _showReloadFlash = false;
  Timer? _reloadFlashTimer;

  void _triggerReloadFlash() {
    if (!mounted) return;
    _reloadFlashTimer?.cancel();
    setState(() => _showReloadFlash = true);
    _reloadFlashTimer = Timer(const Duration(milliseconds: 320), () {
      if (mounted) setState(() => _showReloadFlash = false);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dynamicTitle = widget.title;
    _nativeBridge = NativeBridgeHandler(
      onTitleChanged: (title) {
        if (mounted && title.isNotEmpty) {
          setState(() => _dynamicTitle = title);
        }
      },
      onThemeChanged: (isDark) {
        if (mounted) {
          _updateSystemOverlayStyle(isDark: isDark);
        }
      },
      onConsoleLog: (message, level) {
        if (!mounted) return;
        setState(() {
          _terminalLogs.add(TerminalLogEntry(
            id: '${DateTime.now().microsecondsSinceEpoch}',
            message: message,
            level: level,
            source: 'web',
          ));
          if (_terminalLogs.length > 250) _terminalLogs.removeAt(0);
        });
      },
    );
    _shakeDetector = ShakeDetector(onShake: _openMenuFromShake);
    _shakeDetector.start();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _updateSystemOverlayStyle(isDark: true);
    _loadingStartedAt = DateTime.now();

    if (widget.controlUrl != null) {
      _diagnosticsChannel = PreviewDiagnosticsChannel(
        controlUrl: widget.controlUrl,
        onDiagnostic: _handleRemoteDiagnostic,
        onHealthy: _handleHealthy,
        onLog: (message, level, source) {
          if (!mounted) return;
          setState(() {
            _terminalLogs.add(TerminalLogEntry(
              id: '${DateTime.now().microsecondsSinceEpoch}',
              message: message,
              level: level,
              source: source,
            ));
            if (_terminalLogs.length > 250) _terminalLogs.removeAt(0);
          });
        },
        onConnectionChanged: (connected) {
          if (mounted) setState(() {});
        },
        onBugReportAck: () {
          if (!mounted) return;
          HapticFeedback.mediumImpact();
          _showToast(
            icon: Icons.assignment_turned_in_rounded,
            label: '📋 Screenshot saved to PC & copied to clipboard!',
            color: AppTheme.cyan,
          );
        },
      );
      unawaited(_diagnosticsChannel!.connect());
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.background)
      ..addJavaScriptChannel(
        'PreviewPortNativeBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _nativeBridge.handleMessage(message.message);
        },
      )
      // Preserve the platform browser identity for Flutter engine detection.
      ..setOnConsoleMessage((message) {
        if (!mounted || message.level != JavaScriptLogLevel.error) return;
        _showDiagnostic(PreviewDiagnostic.localError(
          message: message.message,
        ));
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted || _hasError || _isPageReady) return;
            setState(() => _loadingProgress = progress.clamp(0, 100));
            _diagnosticsChannel?.reportProgress(_loadingProgress);
          },
          onPageStarted: (_) {
            _injectBridge();
            if (mounted) {
              _loadingCompletionTimer?.cancel();
              _loadingStartedAt = DateTime.now();
              _diagnosticsChannel?.reportProgress(0);
              setState(() {
                _hasError = false;
                _isPageReady = false;
                _loadingProgress = 0;
              });
            }
          },
          onPageFinished: (_) {
            _injectBridge();
            if (!mounted || _hasError) return;
            setState(() => _loadingProgress = 100);
            _diagnosticsChannel?.reportProgress(100);
            _completeLoadingWhenVisibleLongEnough();
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                _showDiagnostic(
                  PreviewDiagnostic.localError(
                    message: [
                      if (error.description.trim().isNotEmpty)
                        error.description.trim(),
                      if (widget.controlUrl == null)
                        'CLI diagnostics are unavailable for this connection.',
                    ].join(' '),
                  ),
                );
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _injectBridge() {
    EdgeInsets insets = EdgeInsets.zero;
    Size size = Size.zero;
    double pixelRatio = 1.0;

    if (mounted) {
      final mq = MediaQuery.maybeOf(context);
      if (mq != null) {
        insets = mq.padding;
        size = mq.size;
        pixelRatio = mq.devicePixelRatio;
      }
    }

    final bool isLandscape = size.width > size.height;
    final double topInset;
    final double bottomInset;
    final double leftInset;
    final double rightInset;
    final double width;
    final double height;
    final String platform;

    if (_selectedDevice.isNative) {
      topInset = insets.top;
      bottomInset = insets.bottom;
      leftInset = insets.left;
      rightInset = insets.right;
      width = size.width;
      height = size.height;
      platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    } else {
      if (isLandscape) {
        topInset = 0;
        bottomInset = _selectedDevice.bottomInset > 0 ? 21.0 : 0;
        leftInset = _selectedDevice.topInset;
        rightInset = 0;
      } else {
        topInset = _selectedDevice.topInset;
        bottomInset = _selectedDevice.bottomInset;
        leftInset = 0;
        rightInset = 0;
      }
      width = _selectedDevice.width ?? size.width;
      height = _selectedDevice.height ?? size.height;
      platform = _selectedDevice.id == 'android_punch_hole' ? 'android' : 'ios';
    }

    final script = NativeBridgeHandler.buildInjectionScript(
      topInset: topInset,
      bottomInset: bottomInset,
      leftInset: leftInset,
      rightInset: rightInset,
      width: width,
      height: height,
      pixelRatio: pixelRatio,
      platform: platform,
    );

    unawaited(_controller
        .runJavaScript(script)
        .then((_) {
          if (_networkCondition != 'normal') {
            _controller.runJavaScript(
              NativeBridgeHandler.buildSetNetworkConditionScript(_networkCondition),
            );
          }
          if (!_selectedLocation.isRealGps) {
            _controller.runJavaScript(
              NativeBridgeHandler.buildSetMockLocationScript(
                latitude: _selectedLocation.latitude,
                longitude: _selectedLocation.longitude,
              ),
            );
          }
        })
        .catchError((_) {}));
  }

  void _updateInsetsDynamically() {
    if (!mounted) return;
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return;
    final isLandscape = mq.size.width > mq.size.height;
    final double top;
    final double bottom;
    final double left;
    final double right;

    if (_selectedDevice.isNative) {
      top = mq.padding.top;
      bottom = mq.padding.bottom;
      left = mq.padding.left;
      right = mq.padding.right;
    } else {
      if (isLandscape) {
        top = 0;
        bottom = _selectedDevice.bottomInset > 0 ? 21.0 : 0;
        left = _selectedDevice.topInset;
        right = 0;
      } else {
        top = _selectedDevice.topInset;
        bottom = _selectedDevice.bottomInset;
        left = 0;
        right = 0;
      }
    }

    final updateScript = NativeBridgeHandler.buildUpdateInsetsScript(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
    );
    unawaited(_controller.runJavaScript(updateScript).catchError((_) {}));
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _injectBridge();
    _updateInsetsDynamically();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _shakeDetector.start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _shakeDetector.stop();
    }
  }

  void _updateSystemOverlayStyle({required bool isDark}) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadingCompletionTimer?.cancel();
    _reloadFlashTimer?.cancel();
    _shakeDetector.stop();
    unawaited(_diagnosticsChannel?.dispose());
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppTheme.surface,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitDialog();
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Stack(
          children: [
            // 1. RepaintBoundary wrapped Viewport Container
            Positioned.fill(
              child: RepaintBoundary(
                key: _viewportKey,
                child: _buildViewportContent(),
              ),
            ),

            // 2. Horizon Amber Indicator when Simulated Offline Mode is active
            if (_networkCondition == 'offline')
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.warning,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.warning.withValues(alpha: 0.8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),

            // 3. Calm loading progress surface
            if (!_isPageReady && !_hasError)
              Positioned.fill(
                child: ColoredBox(
                  color: AppTheme.background,
                  child: PreviewLoadingProgress(
                    progress: _loadingProgress,
                    projectName: widget.title,
                  ),
                ),
              ),

            // 4. Remote/Local Diagnostics error sheet
            if (_diagnostic != null && !_errorDismissed)
              PreviewErrorSheet(
                diagnostic: _diagnostic!,
                onRetry: _retryPreview,
                onCopyDetails: _copyDiagnostic,
                onDismiss: () {
                  setState(() => _errorDismissed = true);
                },
              ),

            // 5. Ethereal Ghost Capsule HUD (Floating 1-tap hot reload & gestures)
            if (_showFloatingCapsule && !_isMenuOpen)
              FloatingGhostCapsule(
                onHotReload: _triggerRemoteReload,
                onOpenMenu: _openMenuFromShake,
                onOpenTerminal: _openMiniTerminal,
                onAnnotateBug: _openBugAnnotator,
                isCliConnected: _diagnosticsChannel?.isConnected ?? false,
              ),

            // 6. Reload confirmation glow vignette
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showReloadFlash ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 140),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppTheme.cyan.withValues(alpha: 0.8),
                      width: 2.5,
                    ),
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        Colors.transparent,
                        AppTheme.cyan.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 7. Shake Dev Menu Overlay
            _buildMenuOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildViewportContent() {
    final mq = MediaQuery.of(context);
    final isNative = _selectedDevice.isNative;
    final targetW = _selectedDevice.width ?? mq.size.width;
    final targetH = _selectedDevice.height ?? mq.size.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth;
        final availH = constraints.maxHeight;

        final horizontalPadding = isNative ? 0.0 : 32.0;
        final verticalPadding = isNative ? 0.0 : 80.0;
        final scaleX = (availW - horizontalPadding) / targetW;
        final scaleY = (availH - verticalPadding) / targetH;
        final scale = isNative ? 1.0 : (scaleX < scaleY ? scaleX : scaleY).clamp(0.2, 1.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          color: isNative ? AppTheme.background : const Color(0xFF070707),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Top device indicator badge (only shown in simulated device mode)
              if (!isNative)
                Positioned(
                  top: mq.padding.top + 8,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _openViewportSwitcher();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_selectedDevice.icon, size: 13, color: AppTheme.cyan),
                          const SizedBox(width: 6),
                          Text(
                            _selectedDevice.name,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.tune_rounded, size: 12, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),

              // Scaled device chassis frame with fluid morphing
              AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOutCubic,
                  width: targetW,
                  height: targetH,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(isNative ? 0 : _selectedDevice.cornerRadius),
                    border: Border.all(
                      color: isNative ? Colors.transparent : const Color(0xFF333333),
                      width: isNative ? 0 : 3.5,
                    ),
                    boxShadow: isNative
                        ? null
                        : const [
                            BoxShadow(
                              color: Colors.black87,
                              blurRadius: 36,
                              spreadRadius: 8,
                            ),
                          ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _useSafeArea && isNative
                            ? SafeArea(child: WebViewWidget(controller: _controller))
                            : WebViewWidget(controller: _controller),
                      ),

                      // Punch-hole camera cutout if simulated android device
                      if (!isNative && _selectedDevice.hasNotch)
                        Positioned(
                          top: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFF080808),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),

                      // Bottom gesture indicator bar if simulated
                      if (!isNative && _selectedDevice.bottomInset > 0)
                        Positioned(
                          bottom: 6,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 120,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openMenuFromShake() {
    if (!mounted || _isMenuOpen) return;
    HapticFeedback.mediumImpact();
    setState(() => _isMenuOpen = true);
  }

  void _handleRemoteDiagnostic(PreviewDiagnostic diagnostic) {
    if (!mounted) return;
    _showDiagnostic(diagnostic);
  }

  void _handleHealthy() {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 75), () {
      HapticFeedback.mediumImpact();
    });
    _triggerReloadFlash();
    setState(() {
      _diagnostic = null;
      _errorDismissed = false;
      _hasError = false;
    });
  }

  void _showDiagnostic(PreviewDiagnostic diagnostic) {
    if (!mounted) return;
    _loadingCompletionTimer?.cancel();
    _diagnosticsChannel?.reportProgress(_loadingProgress, state: 'failed');
    setState(() {
      _diagnostic = diagnostic;
      _errorDismissed = false;
      _hasError = true;
    });
  }

  void _retryPreview() {
    HapticFeedback.mediumImpact();
    _loadingCompletionTimer?.cancel();
    _loadingStartedAt = DateTime.now();
    _diagnosticsChannel?.reportProgress(0);
    setState(() {
      _diagnostic = null;
      _errorDismissed = false;
      _hasError = false;
      _isPageReady = false;
      _loadingProgress = 0;
    });
    _controller.reload();
  }

  void _triggerRemoteReload() {
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 75), () {
      HapticFeedback.mediumImpact();
    });
    _triggerReloadFlash();

    if (_diagnosticsChannel == null || !_diagnosticsChannel!.isConnected) {
      _showToast(
        icon: Icons.wifi_off_rounded,
        label: 'Workstation CLI channel offline',
        color: AppTheme.warning,
      );
      return;
    }
    _diagnosticsChannel!.triggerHotReload();
    _showToast(
      icon: Icons.bolt_rounded,
      label: '⚡ Hot Reload signal sent',
      color: AppTheme.cyan,
    );
  }

  void _triggerRemoteRestart() {
    HapticFeedback.heavyImpact();
    if (_diagnosticsChannel == null || !_diagnosticsChannel!.isConnected) {
      _showToast(
        icon: Icons.wifi_off_rounded,
        label: 'Workstation CLI channel offline',
        color: AppTheme.warning,
      );
      return;
    }
    _diagnosticsChannel!.triggerHotRestart();
    _showToast(
      icon: Icons.restart_alt_rounded,
      label: '⚡ Hot Restart triggered',
      color: AppTheme.primary,
    );
  }

  Future<void> _openBugAnnotator() async {
    _closeMenu();
    HapticFeedback.mediumImpact();

    try {
      final boundary = _viewportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (ctx) => BugAnnotatorModal(
            screenshotBytes: bytes,
            onSend: (base64Image, notes) {
              if (_diagnosticsChannel == null || !_diagnosticsChannel!.isConnected) {
                _showToast(
                  icon: Icons.wifi_off_rounded,
                  label: 'Workstation offline; cannot beam screenshot',
                  color: AppTheme.warning,
                );
                return;
              }
              _diagnosticsChannel!.sendBugReport(
                base64Image: base64Image,
                notes: notes,
                device: _selectedDevice.name,
              );
              _showToast(
                icon: Icons.cloud_upload_rounded,
                label: 'Beaming screenshot to PC...',
                color: Colors.white70,
              );
            },
          ),
        ),
      );
    } catch (_) {
      _showToast(
        icon: Icons.error_outline_rounded,
        label: 'Could not capture screenshot',
        color: AppTheme.danger,
      );
    }
  }

  void _openMiniTerminal() {
    _closeMenu();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MiniTerminalDrawer(
        logs: _terminalLogs,
        onClear: () {
          setState(() => _terminalLogs.clear());
        },
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showToast({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xF0111111),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        content: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  void _completeLoadingWhenVisibleLongEnough() {
    final startedAt = _loadingStartedAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = _minimumLoadingDisplay - elapsed;

    void complete() {
      if (!mounted || _hasError) return;
      _diagnosticsChannel?.reportProgress(100, state: 'ready');
      setState(() {
        _isPageReady = true;
        _hasError = false;
        _diagnostic = null;
        _errorDismissed = false;
      });
    }

    if (remaining <= Duration.zero) {
      complete();
      return;
    }

    _loadingCompletionTimer?.cancel();
    _loadingCompletionTimer = Timer(remaining, complete);
  }

  void _copyDiagnostic() {
    final diagnostic = _diagnostic;
    if (diagnostic == null) return;
    Clipboard.setData(ClipboardData(text: diagnostic.details));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.surface,
        content: Text(
          'Error details copied',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _closeMenu() {
    if (!mounted || !_isMenuOpen) return;
    HapticFeedback.selectionClick();
    setState(() => _isMenuOpen = false);
  }

  void _openLocationMockSheet() {
    _closeMenu();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LocationMockSheet(
        selected: _selectedLocation,
        onSelect: (preset) {
          Navigator.of(ctx).pop();
          setState(() => _selectedLocation = preset);
          _controller.runJavaScript(
            NativeBridgeHandler.buildSetMockLocationScript(
              latitude: preset.latitude,
              longitude: preset.longitude,
            ),
          );
          _showToast(
            icon: PhosphorIconsRegular.mapPin,
            label: 'Location: ${preset.title}',
            color: AppTheme.cyan,
          );
        },
        onCustom: (lat, lng, name) {
          final customPreset = MockLocationPreset(
            id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
            title: name,
            subtitle: '${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°',
            latitude: lat,
            longitude: lng,
            icon: PhosphorIconsRegular.pencilSimple,
          );
          setState(() => _selectedLocation = customPreset);
          _controller.runJavaScript(
            NativeBridgeHandler.buildSetMockLocationScript(
              latitude: lat,
              longitude: lng,
            ),
          );
          _showToast(
            icon: PhosphorIconsRegular.mapPin,
            label: 'Location: $name',
            color: AppTheme.cyan,
          );
        },
      ),
    );
  }

  void _openViewportSwitcher() {
    _closeMenu();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ViewportSwitcherSheet(
        selected: _selectedDevice,
        onSelect: (device) {
          Navigator.of(ctx).pop();
          setState(() => _selectedDevice = device);
          _injectBridge();
          _showToast(
            icon: device.icon,
            label: 'Viewport: ${device.name}',
            color: AppTheme.cyan,
          );
        },
      ),
    );
  }

  Widget _buildMenuOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_isMenuOpen,
        child: AnimatedOpacity(
          opacity: _isMenuOpen ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _closeMenu,
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.62),
              child: Center(
                child: GestureDetector(
                  onTap: () {},
                  child: AnimatedScale(
                    scale: _isMenuOpen ? 1 : 0.94,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: _buildExpandedMenu(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedMenu() {
    final isCliConnected = _diagnosticsChannel?.isConnected ?? false;

    return Container(
      width: 290,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xF7101216),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x33FFFFFF),
          width: 0.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dynamicTitle ?? 'Preview controls',
                      style: AppTypography.modalTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 5.5,
                          height: 5.5,
                          decoration: BoxDecoration(
                            color: isCliConnected ? AppTheme.cyan : AppTheme.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isCliConnected ? 'CLI Live Synced' : 'Native Bridge Active',
                          style: AppTypography.monoData(
                            color: isCliConnected ? AppTheme.cyan : AppTheme.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isMenuOpen = false);
                },
                child: const Icon(
                  PhosphorIconsRegular.x,
                  size: 17,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hot Reload & Restart Quick Action Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0x1800E5FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x3300E5FF), width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _triggerRemoteReload,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            PhosphorIconsRegular.lightning,
                            size: 16,
                            color: AppTheme.cyan,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Hot Reload',
                            style: AppTypography.button(
                              fontSize: 12,
                              color: AppTheme.cyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 18,
                  color: const Color(0x3300E5FF),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _triggerRemoteRestart,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          PhosphorIconsRegular.arrowsClockwise,
                          size: 15,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Restart',
                          style: AppTypography.button(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Network Conditioning Segment Selector
          Text(
            'NETWORK CONDITIONING',
            style: AppTypography.sectionHud(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF14161A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
            ),
            child: Row(
              children: [
                _buildNetworkSegment('normal', 'Normal'),
                _buildNetworkSegment('3g', '3G Throttle'),
                _buildNetworkSegment('offline', 'Offline'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Simulation Drawer Links (Location & Viewport)
          _buildMenuNavRow(
            icon: PhosphorIconsRegular.mapPin,
            label: 'Location',
            currentValue: _selectedLocation.title,
            onTap: _openLocationMockSheet,
          ),
          _buildMenuNavRow(
            icon: PhosphorIconsRegular.deviceMobile,
            label: 'Viewport',
            currentValue: _selectedDevice.name,
            onTap: _openViewportSwitcher,
          ),
          _buildMenuNavRow(
            icon: PhosphorIconsRegular.terminalWindow,
            label: 'Console Logs',
            currentValue: '${_terminalLogs.length} events',
            onTap: _openMiniTerminal,
          ),
          _buildMenuNavRow(
            icon: PhosphorIconsRegular.camera,
            label: 'Annotate Bug',
            currentValue: 'Send to PC',
            onTap: _openBugAnnotator,
          ),

          const Divider(height: 14, color: AppTheme.borderSubtle),

          // Maintenance & Toggles
          _buildMenuRow(
            icon: _showFloatingCapsule
                ? PhosphorIconsRegular.eye
                : PhosphorIconsRegular.eyeSlash,
            label: _showFloatingCapsule ? 'Hide floating HUD' : 'Show floating HUD',
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showFloatingCapsule = !_showFloatingCapsule);
            },
          ),
          _buildMenuRow(
            icon: PhosphorIconsRegular.arrowsClockwise,
            label: 'Reload webview',
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _isMenuOpen = false);
              _controller.reload();
            },
          ),
          _buildMenuRow(
            icon: PhosphorIconsRegular.trash,
            label: 'Clear cache & reload',
            onTap: () async {
              HapticFeedback.mediumImpact();
              setState(() => _isMenuOpen = false);
              await _controller.clearCache();
              _controller.reload();
            },
          ),
          _buildMenuRow(
            icon: _useSafeArea
                ? PhosphorIconsRegular.cornersOut
                : PhosphorIconsRegular.cornersIn,
            label: _useSafeArea ? 'Use full screen' : 'Use safe area',
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _useSafeArea = !_useSafeArea;
                _isMenuOpen = false;
              });
            },
          ),
          _buildMenuRow(
            icon: PhosphorIconsRegular.copy,
            label: 'Copy preview link',
            onTap: () {
              HapticFeedback.selectionClick();
              Clipboard.setData(ClipboardData(text: widget.url));
              setState(() => _isMenuOpen = false);
              _showToast(
                icon: PhosphorIconsRegular.checkCircle,
                label: 'Preview link copied',
                color: AppTheme.cyan,
              );
            },
          ),
          const Divider(height: 14, color: AppTheme.borderSubtle),
          _buildMenuRow(
            icon: PhosphorIconsRegular.x,
            label: 'Return to scanner',
            color: AppTheme.danger,
            onTap: () {
              HapticFeedback.heavyImpact();
              setState(() => _isMenuOpen = false);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSegment(String condition, String label) {
    final isSelected = _networkCondition == condition;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (condition == 'offline') {
            HapticFeedback.heavyImpact();
          } else {
            HapticFeedback.selectionClick();
          }
          setState(() => _networkCondition = condition);
          _controller.runJavaScript(
            NativeBridgeHandler.buildSetNetworkConditionScript(condition),
          );
          _showToast(
            icon: condition == 'offline'
                ? PhosphorIconsRegular.wifiSlash
                : condition == '3g'
                    ? PhosphorIconsRegular.cellSignalMedium
                    : PhosphorIconsRegular.wifiHigh,
            label: 'Network: $label',
            color: condition == 'offline' ? AppTheme.danger : AppTheme.cyan,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.button(
                fontSize: 10.5,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuNavRow({
    required IconData icon,
    required String label,
    required String currentValue,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 15, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.body(fontSize: 12.5),
            ),
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                currentValue,
                style: AppTypography.monoData(color: AppTheme.cyan),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              PhosphorIconsRegular.caretRight,
              size: 13,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body(fontSize: 12, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Text(
          'Exit Preview?',
          style: AppTypography.cardTitle(),
        ),
        content: Text(
          'Return to the home dashboard?',
          style: AppTypography.body(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: AppTypography.button(color: AppTheme.textSecondary),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            child: Text('Exit', style: AppTypography.button(color: Colors.black)),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
