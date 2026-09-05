import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_theme.dart';

class AppViewerScreen extends StatefulWidget {
  final String url;
  final String? title;

  const AppViewerScreen({super.key, required this.url, this.title});

  @override
  State<AppViewerScreen> createState() => _AppViewerScreenState();
}

class _AppViewerScreenState extends State<AppViewerScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;
  bool _isPageReady = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isMenuOpen = false;
  bool _useSafeArea = false;

  // Draggable position for the floating dev pill
  Offset _pillPosition = const Offset(16, 52);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.background)
      ..setUserAgent('PreviewPort/1.0 (Live Flutter Preview; iOS/Android)')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress);
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _hasError = false;
                _isPageReady = false;
                _loadingProgress = 0;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _loadingProgress = 100;
                _isPageReady = true;
              });
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _isPageReady = false;
                  _errorMessage = error.description;
                });
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
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
    final media = MediaQuery.of(context);

    final clampedX = _pillPosition.dx.clamp(12.0, media.size.width - 90.0);
    final clampedY = _pillPosition.dy.clamp(40.0, media.size.height - 120.0);

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

            // Keep startup polished while Flutter initializes its web engine.
            if (!_isPageReady && !_hasError)
              Positioned.fill(
                child: ColoredBox(
                  color: AppTheme.background,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.lightBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.title ?? 'Launching preview',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _loadingProgress == 0
                              ? 'Connecting to development server…'
                              : 'Loading $_loadingProgress%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 2. Minimalist Loading Progress Indicator
            if (_loadingProgress < 100 && !_hasError)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: LinearProgressIndicator(
                    value: _loadingProgress / 100.0,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.lightBlue,
                    ),
                    minHeight: 2,
                  ),
                ),
              ),

            // 3. Minimalist Connection Error Fallback
            if (_hasError)
              Container(
                color: AppTheme.background,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          size: 24,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Unable to Connect',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _errorMessage ??
                            'Make sure your computer and phone are connected to the same network.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          widget.url,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Retry'),
                            onPressed: () {
                              setState(() {
                                _hasError = false;
                                _isPageReady = false;
                                _loadingProgress = 0;
                              });
                              _controller.reload();
                            },
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: const BorderSide(color: AppTheme.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Scanner'),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // 4. Draggable Floating Dev Pill
            Positioned(
              left: clampedX,
              top: clampedY,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _pillPosition = Offset(
                      _pillPosition.dx + details.delta.dx,
                      _pillPosition.dy + details.delta.dy,
                    );
                  });
                },
                child: _buildFloatingDevPill(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingDevPill() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: const Color(0xF20D1B2E), // Frosted Dark Slate Navy
        borderRadius: BorderRadius.circular(_isMenuOpen ? 14 : 20),
        border: Border.all(color: AppTheme.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: _isMenuOpen ? _buildExpandedMenu() : _buildCollapsedPill(),
    );
  }

  Widget _buildCollapsedPill() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isMenuOpen = true);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'DEV',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedMenu() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DEV TOOLS',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isMenuOpen = false);
                },
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
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
            label: 'Reload App',
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _isMenuOpen = false);
              _controller.reload();
            },
          ),
          _buildMenuRow(
            icon: Icons.cleaning_services_rounded,
            label: 'Clear Cache',
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
            label: _useSafeArea ? 'Full Bleed' : 'Safe Area',
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
            label: 'Copy URL',
            onTap: () {
              HapticFeedback.selectionClick();
              Clipboard.setData(ClipboardData(text: widget.url));
              setState(() => _isMenuOpen = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppTheme.surface,
                  content: Text(
                    'URL copied to clipboard',
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
            label: 'Exit to Home',
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
