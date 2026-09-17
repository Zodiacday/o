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
import '../services/device_viewport_sensor.dart';
import '../models/preview_diagnostic.dart';
import '../models/network_request_entry.dart';
import '../widgets/preview_loading_progress.dart';
import '../widgets/preview_error_sheet.dart';
import '../widgets/location_mock_sheet.dart';
import '../widgets/viewport_switcher_sheet.dart';
import '../widgets/liquid_sidebar_seed.dart';
import '../widgets/mini_terminal_drawer.dart';
import '../widgets/bug_annotator_modal.dart';

part 'app_viewer_controls.dart';
part 'app_viewer_menu.dart';

class AppViewerScreen extends StatefulWidget {
  final String url;
  final String? title;
  final String? controlUrl;
  final WebViewController? preloadedController;

  const AppViewerScreen({
    super.key,
    required this.url,
    this.title,
    this.controlUrl,
    this.preloadedController,
  });

  @override
  State<AppViewerScreen> createState() => _AppViewerScreenState();
}

class _AppViewerScreenState extends State<AppViewerScreen>
    with WidgetsBindingObserver {
  static const _minimumLoadingDisplay = Duration(milliseconds: 200);

  late final WebViewController _controller;
  late final NativeBridgeHandler _nativeBridge;
  final GlobalKey _viewportKey = GlobalKey();

  String? _dynamicTitle;
  int _loadingProgress = 0;
  bool _isPageReady = false;
  bool _hasError = false;
  PreviewDiagnostic? _diagnostic;
  bool _errorDismissed = false;
  late final LiquidDevControlController _liquidMenuController;
  bool _isDarkContent = true;
  Color? _appBackgroundColor;
  final bool _showFloatingCapsule = true;
  late final ShakeDetector _shakeDetector;
  PreviewDiagnosticsChannel? _diagnosticsChannel;
  Timer? _loadingCompletionTimer;
  DateTime? _loadingStartedAt;

  // PreviewPort 2.0 Simulation & Log State
  final String _networkCondition = 'normal'; // 'normal' | '3g' | 'offline'
  final MockLocationPreset _selectedLocation = defaultLocationPresets.first;
  SimulatedDeviceProfile _selectedDevice = defaultDeviceProfiles.first;
  SimulatedDeviceProfile? _nativeDevice;
  final List<TerminalLogEntry> _terminalLogs = [];
  final List<NetworkRequestEntry> _networkRequests = [];
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
    _liquidMenuController = LiquidDevControlController();
    _dynamicTitle = widget.title;
    _nativeBridge = NativeBridgeHandler(
      onTitleChanged: (title) {
        if (mounted && title.isNotEmpty) {
          setState(() => _dynamicTitle = title);
        }
      },
      onThemeChanged: (isDark) {
        if (mounted) {
          setState(() => _isDarkContent = isDark);
          _updateSystemOverlayStyle(isDark: isDark);
        }
      },
      onThemeColorDetected: (color) {
        if (mounted) {
          setState(() => _appBackgroundColor = color);
          try {
            _controller.setBackgroundColor(color);
          } catch (_) {}
        }
      },
      onPageReady: () {
        if (mounted) {
          _signalPageReady();
        }
      },
      onConsoleLog: (message, level) {
        if (!mounted) return;
        setState(() {
          _terminalLogs.add(
            TerminalLogEntry(
              id: '${DateTime.now().microsecondsSinceEpoch}',
              message: message,
              level: level,
              source: 'web',
            ),
          );
          if (_terminalLogs.length > 250) _terminalLogs.removeAt(0);
        });
      },
      onNetworkRequest: (entry) {
        if (!mounted) return;
        setState(() {
          _networkRequests.add(entry);
          if (_networkRequests.length > 250) _networkRequests.removeAt(0);
        });
      },
      onFatalError: (message, file, line) {
        if (!mounted) return;
        final location = (file != null && file.isNotEmpty)
            ? ' at ${file.split('/').last}${line != null ? ':$line' : ''}'
            : '';
        final fullMsg = '$message$location';
        setState(() {
          _terminalLogs.add(
            TerminalLogEntry(
              id: '${DateTime.now().microsecondsSinceEpoch}',
              message: '💥 [Fatal Startup Error] $fullMsg',
              level: 'error',
              source: 'web',
            ),
          );
          if (_terminalLogs.length > 250) _terminalLogs.removeAt(0);
        });
      },
      onBlankScreenDetected: (reason) {
        if (!mounted || _hasError) return;
        setState(() {
          _terminalLogs.add(
            TerminalLogEntry(
              id: '${DateTime.now().microsecondsSinceEpoch}',
              message: '⚠️ [Watchdog] $reason',
              level: 'error',
              source: 'watchdog',
            ),
          );
          if (_terminalLogs.length > 250) _terminalLogs.removeAt(0);
        });
      },
    );
    _shakeDetector = ShakeDetector(onShake: _openMenuFromShake);
    _shakeDetector.start();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _updateSystemOverlayStyle(isDark: true);
    _loadingStartedAt = DateTime.now();
    _initializeDiagnostics();
    _initializeWebView();
  }

  void _initializeDiagnostics() {
    if (widget.controlUrl == null) return;
    _diagnosticsChannel = PreviewDiagnosticsChannel(
      controlUrl: widget.controlUrl,
      onDiagnostic: _handleRemoteDiagnostic,
      onHealthy: _handleHealthy,
      onLog: (message, level, source) {
        if (!mounted) return;
        setState(() {
          _terminalLogs.add(
            TerminalLogEntry(
              id: '${DateTime.now().microsecondsSinceEpoch}',
              message: message,
              level: level,
              source: source,
            ),
          );
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

  void _initializeWebView() {
    _controller = widget.preloadedController ?? WebViewController();
    _controller
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
        if (!mounted) return;
        setState(() {
          _terminalLogs.add(
            TerminalLogEntry(
              id: '${DateTime.now().microsecondsSinceEpoch}',
              message: message.message,
              level: message.level == JavaScriptLogLevel.error
                  ? 'error'
                  : message.level == JavaScriptLogLevel.warning
                      ? 'warn'
                      : 'info',
              source: 'console',
            ),
          );
          if (_terminalLogs.length > 250) _terminalLogs.removeAt(0);
        });
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final syncDetected = DeviceViewportSensor.detectSync(context);
    if (_nativeDevice == null) {
      // First detection — set as default selected device.
      _nativeDevice = syncDetected;
      if (_selectedDevice.isNative) {
        _selectedDevice = syncDetected;
      }
    } else {
      _nativeDevice = syncDetected;
      if (_selectedDevice.isNative) {
        _selectedDevice = syncDetected;
      }
    }

    // Authoritative model detection from native platform channel
    DeviceViewportSensor.detect(context).then((authoritative) {
      if (!mounted) return;
      if (_nativeDevice?.name != authoritative.name) {
        setState(() {
          _nativeDevice = authoritative;
          if (_selectedDevice.isNative) {
            _selectedDevice = authoritative;
          }
        });
      }
    });
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
      // Use sensor-populated native profile values when available.
      final native = _nativeDevice;
      final rawTop = native?.topInset ?? insets.top;
      final rawBottom = native?.bottomInset ?? insets.bottom;
      topInset = rawTop;
      bottomInset = rawBottom;
      leftInset = insets.left;
      rightInset = insets.right;
      width = native?.width ?? size.width;
      height = native?.height ?? size.height;
      platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';
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

    unawaited(
      _controller
          .runJavaScript(script)
          .then((_) {
            if (_networkCondition != 'normal') {
              _controller.runJavaScript(
                NativeBridgeHandler.buildSetNetworkConditionScript(
                  _networkCondition,
                ),
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
          .catchError((_) {}),
    );
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
      final native = _nativeDevice;
      final rawTop = native?.topInset ?? mq.padding.top;
      final rawBottom = native?.bottomInset ?? mq.padding.bottom;
      top = rawTop;
      bottom = rawBottom;
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
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadingCompletionTimer?.cancel();
    _reloadFlashTimer?.cancel();
    _liquidMenuController.dispose();
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
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_liquidMenuController.isOpen) {
          await _liquidMenuController.dismiss();
          return;
        }
        _showExitDialog();
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

            // 3. Calm loading progress surface with smooth GPU fade-out
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _isPageReady || _hasError,
                child: AnimatedOpacity(
                  opacity: (!_isPageReady && !_hasError) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  child: ColoredBox(
                    color: AppTheme.background,
                    child: PreviewLoadingProgress(
                      progress: _loadingProgress,
                      projectName: widget.title,
                    ),
                  ),
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

            // 5. Reload confirmation glow vignette
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

            // 6. Unified nano seed, tool orbit, and morphing menu surface.
            if (_showFloatingCapsule) _buildMenuOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildViewportContent() {
    final mq = MediaQuery.of(context);
    final isNative = _selectedDevice.isNative;

    if (isNative) {
      final effectiveBg = _appBackgroundColor ??
          (_isDarkContent ? AppTheme.background : Colors.white);

      return ColoredBox(
        color: effectiveBg,
        child: WebViewWidget(controller: _controller),
      );
    }

    final targetW = _selectedDevice.width ?? mq.size.width;
    final targetH = _selectedDevice.height ?? mq.size.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth;
        final availH = constraints.maxHeight;

        const horizontalPadding = 32.0;
        const verticalPadding = 80.0;
        final scaleX = (availW - horizontalPadding) / targetW;
        final scaleY = (availH - verticalPadding) / targetH;
        final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.2, 1.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          color: const Color(0xFF070707),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Top device indicator badge (only shown in simulated device mode)
              Positioned(
                top: mq.padding.top + 8,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _openViewportSwitcher();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedDevice.icon,
                          size: 13,
                          color: AppTheme.cyan,
                        ),
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
                        const Icon(
                          Icons.tune_rounded,
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
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
                    borderRadius: BorderRadius.circular(
                      _selectedDevice.cornerRadius,
                    ),
                    border: Border.all(
                      color: const Color(0xFF333333),
                      width: 3.5,
                    ),
                    boxShadow: const [
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
                        child: WebViewWidget(controller: _controller),
                      ),

                      // Punch-hole camera cutout if simulated android device
                      if (_selectedDevice.hasNotch)
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
                      if (_selectedDevice.bottomInset > 0)
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
}
