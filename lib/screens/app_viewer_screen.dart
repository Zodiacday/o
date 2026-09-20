import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';
import '../services/shake_detector.dart';
import '../services/preview_diagnostics_channel.dart';
import '../models/preview_diagnostic.dart';
import '../widgets/preview_loading_progress.dart';
import '../widgets/preview_error_sheet.dart';

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
  int _loadingProgress = 0;
  bool _isPageReady = false;
  bool _hasError = false;
  PreviewDiagnostic? _diagnostic;
  bool _errorDismissed = false;
  bool _isMenuOpen = false;
  bool _useSafeArea = false;
  late final ShakeDetector _shakeDetector;
  PreviewDiagnosticsChannel? _diagnosticsChannel;
  Timer? _loadingCompletionTimer;
  DateTime? _loadingStartedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shakeDetector = ShakeDetector(onShake: _openMenuFromShake);
    _shakeDetector.start();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadingStartedAt = DateTime.now();

    if (widget.controlUrl != null) {
      _diagnosticsChannel = PreviewDiagnosticsChannel(
        controlUrl: widget.controlUrl,
        onDiagnostic: _handleRemoteDiagnostic,
        onHealthy: _handleHealthy,
      );
      unawaited(_diagnosticsChannel!.connect());
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.background)
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _shakeDetector.start();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _shakeDetector.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadingCompletionTimer?.cancel();
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
            // 1. Zero-Chrome Fullscreen Native WebView Container
            Positioned.fill(
              child: _useSafeArea
                  ? SafeArea(child: WebViewWidget(controller: _controller))
                  : WebViewWidget(controller: _controller),
            ),

            // Keep startup focused on one calm, live progress surface while
            // Flutter initializes its web engine.
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

            // Keep the live preview visible while diagnostics slide up.
            if (_diagnostic != null && !_errorDismissed)
              PreviewErrorSheet(
                diagnostic: _diagnostic!,
                onRetry: _retryPreview,
                onCopyDetails: _copyDiagnostic,
                onDismiss: () {
                  setState(() => _errorDismissed = true);
                },
              ),

            _buildMenuOverlay(),
          ],
        ),
      ),
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
    return Container(
      width: 278,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xF20A0A0A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.previewBorder.withValues(alpha: 0.8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 34,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Preview controls',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isMenuOpen = false);
                },
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          const SizedBox(height: 4),
          _buildMenuRow(
            icon: Icons.refresh_rounded,
            label: 'Reload preview',
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _isMenuOpen = false);
              _controller.reload();
            },
          ),
          _buildMenuRow(
            icon: Icons.cleaning_services_rounded,
            label: 'Clear preview data',
            onTap: () async {
              HapticFeedback.mediumImpact();
              setState(() => _isMenuOpen = false);
              await _controller.clearCache();
              _controller.reload();
            },
          ),
          _buildMenuRow(
            icon: _useSafeArea
                ? Icons.fullscreen_rounded
                : Icons.fullscreen_exit_rounded,
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
            icon: Icons.copy_rounded,
            label: 'Copy preview link',
            onTap: () {
              HapticFeedback.selectionClick();
              Clipboard.setData(ClipboardData(text: widget.url));
              setState(() => _isMenuOpen = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.surface,
                  content: Text(
                    'Preview link copied',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          const SizedBox(height: 4),
          _buildMenuRow(
            icon: Icons.close_rounded,
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
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
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Return to the home dashboard?',
          style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            child: const Text('Exit'),
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
