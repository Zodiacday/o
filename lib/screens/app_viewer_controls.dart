// These methods are part of the private State implementation; splitting them
// keeps the screen readable while retaining Flutter's existing state owner.
// ignore_for_file: invalid_use_of_protected_member

part of 'app_viewer_screen.dart';

extension _AppViewerControls on _AppViewerScreenState {
  void _openMenuFromShake() {
    if (!mounted || _liquidMenuController.isOpen) return;
    HapticFeedback.mediumImpact();
    unawaited(_liquidMenuController.openMenu());
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

  // Kept for the upcoming annotation node in the liquid control system.
  // ignore: unused_element
  Future<void> _openBugAnnotator() async {
    _closeMenu();
    HapticFeedback.mediumImpact();

    try {
      final boundary =
          _viewportKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
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
              if (_diagnosticsChannel == null ||
                  !_diagnosticsChannel!.isConnected) {
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
        networkRequests: _networkRequests,
        onClear: () {
          setState(() => _terminalLogs.clear());
        },
        onClearNetwork: () {
          setState(() => _networkRequests.clear());
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

  void _signalPageReady() {
    if (!mounted || _hasError || _isPageReady) return;
    _loadingCompletionTimer?.cancel();
    _diagnosticsChannel?.reportProgress(100, state: 'ready');
    setState(() {
      _isPageReady = true;
      _hasError = false;
      _diagnostic = null;
      _errorDismissed = false;
    });
  }

  void _completeLoadingWhenVisibleLongEnough() {
    if (_isPageReady) return;
    final startedAt = _loadingStartedAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = _AppViewerScreenState._minimumLoadingDisplay - elapsed;

    if (remaining <= Duration.zero) {
      _signalPageReady();
      return;
    }

    _loadingCompletionTimer?.cancel();
    _loadingCompletionTimer = Timer(remaining, _signalPageReady);
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
}
