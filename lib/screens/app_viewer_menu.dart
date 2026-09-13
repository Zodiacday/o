// ignore_for_file: invalid_use_of_protected_member

part of 'app_viewer_screen.dart';

extension _AppViewerMenu on _AppViewerScreenState {
  void _closeMenu() {
    if (!mounted || !_isMenuOpen) return;
    HapticFeedback.selectionClick();
    setState(() => _isMenuOpen = false);
  }

  void _openViewportSwitcher() {
    _closeMenu();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ViewportSwitcherSheet(
        selected: _selectedDevice,
        nativeDevice: _nativeDevice,
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
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final anchorY = _capsulePixelY ??
        FloatingGhostCapsule.calculateCenterY(
          screenH: screenH,
          topInset: mq.padding.top,
          bottomInset: mq.padding.bottom,
          dy: _capsuleDy,
        );

    return LiquidDevMenuOverlay(
      isOpen: _isMenuOpen,
      onClose: _closeMenu,
      anchorY: anchorY,
      isRightSide: _capsuleIsRightSide,
      title: _dynamicTitle,
      isCliConnected: _diagnosticsChannel?.isConnected ?? false,
      onHotReload: _triggerRemoteReload,
      onRestart: _triggerRemoteRestart,
      onOpenViewportSwitcher: _openViewportSwitcher,
      onOpenTerminal: _openMiniTerminal,
      terminalLogCount: _terminalLogs.length,
      selectedDeviceName: _selectedDevice.name,
      selectedDeviceIcon: _selectedDevice.icon,
      onClearCache: () async {
        HapticFeedback.mediumImpact();
        _closeMenu();
        await _controller.clearCache();
        _controller.reload();
        _showToast(
          icon: PhosphorIconsRegular.checkCircle,
          label: 'Cache cleared & reloaded',
          color: AppTheme.cyan,
        );
      },
      onExit: () {
        HapticFeedback.heavyImpact();
        _closeMenu();
        _showExitDialog();
      },
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
        title: Text('Exit Preview?', style: AppTypography.cardTitle()),
        content: Text(
          'Return to the scanner dashboard?',
          style: AppTypography.body(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
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
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text(
              'Exit',
              style: AppTypography.button(color: Colors.white),
            ),
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
