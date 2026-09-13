// ignore_for_file: invalid_use_of_protected_member

part of 'app_viewer_screen.dart';

extension _AppViewerMenu on _AppViewerScreenState {
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
        border: Border.all(color: const Color(0x33FFFFFF), width: 0.8),
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
                            color: isCliConnected
                                ? AppTheme.cyan
                                : AppTheme.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isCliConnected
                              ? 'CLI Live Synced'
                              : 'Native Bridge Active',
                          style: AppTypography.monoData(
                            color: isCliConnected
                                ? AppTheme.cyan
                                : AppTheme.textSecondary,
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
                Container(width: 1, height: 18, color: const Color(0x3300E5FF)),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _triggerRemoteRestart,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
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
            label: _showFloatingCapsule
                ? 'Hide floating HUD'
                : 'Show floating HUD',
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
            color: isSelected
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.transparent,
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
            Text(label, style: AppTypography.body(fontSize: 12.5)),
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
        title: Text('Exit Preview?', style: AppTypography.cardTitle()),
        content: Text(
          'Return to the home dashboard?',
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
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            child: Text(
              'Exit',
              style: AppTypography.button(color: Colors.black),
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
