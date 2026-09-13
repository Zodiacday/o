part of 'quick_connect_tab.dart';

extension _QuickConnectSections on _QuickConnectTabState {
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
