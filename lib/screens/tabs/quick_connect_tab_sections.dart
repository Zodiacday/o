part of 'quick_connect_tab.dart';

extension _QuickConnectSections on _QuickConnectTabState {
  Widget _buildWorkstationHud() {
    return Bounceable(
      scaleFactor: 0.98,
      onTap: () {
        HapticFeedback.lightImpact();
        _showEditHostDialog();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF090C14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHostReachable
                ? const Color(0xFF192233)
                : AppTheme.warning.withValues(alpha: 0.40),
            width: 0.9,
          ),
          boxShadow: [
            if (!_isHostReachable)
              BoxShadow(
                color: AppTheme.warning.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF101624),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF1C283E),
                          width: 0.8,
                        ),
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.desktop,
                        size: 17,
                        color: AppTheme.cyan,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: _isHostReachable
                              ? AppTheme.statusGreen
                              : AppTheme.warning,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF090C14),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isHostReachable
                                      ? AppTheme.statusGreen
                                      : AppTheme.warning)
                                  .withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _targetHost,
                        style: AppTypography.monoData(
                          fontSize: 14.5,
                          color: Colors.white,
                        ).copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'TARGET WORKSTATION',
                        style: AppTypography.monoData(
                          fontSize: 9,
                          color: AppTheme.textMuted,
                        ).copyWith(letterSpacing: 0.6),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _isHostReachable
                            ? AppTheme.statusGreen.withValues(alpha: 0.10)
                            : AppTheme.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: _isHostReachable
                              ? AppTheme.statusGreen.withValues(alpha: 0.28)
                              : AppTheme.warning.withValues(alpha: 0.35),
                          width: 0.7,
                        ),
                      ),
                      child: Text(
                        _isHostReachable ? 'ONLINE' : 'UNREACHABLE',
                        style: AppTypography.monoData(
                          fontSize: 8.5,
                          color: _isHostReachable
                              ? AppTheme.statusGreen
                              : AppTheme.warning,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      PhosphorIconsRegular.pencilSimple,
                      size: 13,
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
              ],
            ),
            if (!_isHostReachable) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.20),
                    width: 0.7,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      PhosphorIconsRegular.warningCircle,
                      size: 12,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Host timed out. Tap to change IP or check your Wi-Fi.',
                        style: AppTypography.monoData(
                          fontSize: 10,
                          color: AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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
        widget.onLaunchApp(
          url,
          title: isTunnel ? 'Cloud Tunnel' : 'Clipboard Link',
        );
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
      itemCount: 4,
      itemBuilder: (context, index) {
        final preset = _slots[index];
        if (preset == null) {
          return _buildEmptySlotCard(index);
        }

        final isPinned = _pinnedSlots.containsKey(index);
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
                    : (isPinned
                        ? AppTheme.cyan.withValues(alpha: 0.25)
                        : const Color(0xFF1B2232)),
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
                              horizontal: 4,
                              vertical: 1.5,
                            ),
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
                        if (isPinned) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.cyan.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppTheme.cyan.withValues(alpha: 0.35),
                                width: 0.7,
                              ),
                            ),
                            child: Text(
                              'PINNED',
                              style: AppTypography.monoData(
                                fontSize: 7.5,
                                color: AppTheme.cyan,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        // Live / Idle glowing beacon dot
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isLive
                                ? AppTheme.statusGreen
                                : const Color(0xFF384358),
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (isLive)
                                BoxShadow(
                                  color: AppTheme.statusGreen.withValues(
                                    alpha: 0.7,
                                  ),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
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
                Text(
                  preset.framework,
                  style: AppTypography.headline().copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptySlotCard(int index) {
    return Bounceable(
      scaleFactor: 0.96,
      onTap: () {
        HapticFeedback.lightImpact();
        _showEditPresetDialog(index);
      },
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFF07090E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF161D2B),
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
                Text(
                  'SLOT ${index + 1}',
                  style: AppTypography.monoCounter(
                    color: AppTheme.textMuted,
                  ).copyWith(fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: const Color(0xFF1B2232),
                      width: 0.7,
                    ),
                  ),
                  child: Text(
                    'EMPTY',
                    style: AppTypography.monoData(
                      fontSize: 8,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.cyan.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.cyan.withValues(alpha: 0.20),
                      width: 0.7,
                    ),
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.plus,
                    size: 13,
                    color: AppTheme.cyan,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Assign Port',
                    style: AppTypography.headline().copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
