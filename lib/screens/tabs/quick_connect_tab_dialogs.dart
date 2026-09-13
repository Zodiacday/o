part of 'quick_connect_tab.dart';

extension _QuickConnectDialogs on _QuickConnectTabState {
  void _showEditHostDialog() {
    final controller = TextEditingController(text: _targetHost);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.borderSubtle),
        ),
        title: Text('Target Workstation IP', style: AppTypography.modalTitle()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your computer\'s local Wi-Fi or LAN IP address.',
              style: AppTypography.subtitle(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: AppTypography.monoData(fontSize: 14, color: Colors.white),
              cursorColor: AppTheme.cyan,
              decoration: InputDecoration(
                hintText: '192.168.1.100',
                hintStyle: AppTypography.monoData(color: AppTheme.textMuted),
                filled: true,
                fillColor: const Color(0xFF0C101A),
                prefixIcon: const Icon(
                  PhosphorIconsRegular.desktop,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.cyan),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.button(color: AppTheme.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _setTargetHost(controller.text);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.cyan,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save Host'),
          ),
        ],
      ),
    );
  }

  void _showSlotPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            decoration: BoxDecoration(
              color: const Color(0xFA0B0E17),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: const Color(0xFF1B2232), width: 0.9),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF243044),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customize Matrix Slots',
                      style: AppTypography.modalTitle(),
                    ),
                    if (_isCustomPinned)
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _resetToAutoAdaptive();
                        },
                        child: Text(
                          'Reset All to Auto',
                          style: AppTypography.monoData(
                            fontSize: 11,
                            color: AppTheme.cyan,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a slot to configure its port, framework signature, or protocol.',
                  style: AppTypography.subtitle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                ...List.generate(_presets.length, (i) {
                  final preset = _presets[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Bounceable(
                      scaleFactor: 0.98,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _showEditPresetDialog(i);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121724),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF1E283C),
                            width: 0.8,
                          ),
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
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: AppTypography.monoCounter(
                                    color: AppTheme.cyan,
                                  ).copyWith(fontSize: 14),
                                ),
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
                                        ':${preset.port}',
                                        style: AppTypography.monoData(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (preset.isHttps) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.cyan.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
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
                                  Text(
                                    preset.framework,
                                    style: AppTypography.subtitle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              PhosphorIconsRegular.pencilSimple,
                              size: 15,
                              color: AppTheme.cyan,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditPresetDialog(int slotIndex) {
    final currentPreset = _presets[slotIndex];
    final portController = TextEditingController(
      text: currentPreset.port.toString(),
    );
    final nameController = TextEditingController(text: currentPreset.framework);
    var isHttps = currentPreset.isHttps;
    var userModifiedName = false;

    // Quick-pick framework chips
    final quickFrameworks = [
      (port: 5173, label: 'Vite', icon: PhosphorIconsRegular.lightning),
      (port: 3000, label: 'Next.js', icon: PhosphorIconsRegular.code),
      (port: 4200, label: 'Angular', icon: PhosphorIconsRegular.browsers),
      (
        port: 8081,
        label: 'React Native',
        icon: PhosphorIconsRegular.deviceMobile,
      ),
      (port: 8000, label: 'FastAPI', icon: PhosphorIconsRegular.terminalWindow),
      (port: 5000, label: 'Flask', icon: PhosphorIconsRegular.terminalWindow),
      (
        port: 8080,
        label: 'Flutter Web',
        icon: PhosphorIconsRegular.deviceMobile,
      ),
      (port: 1234, label: 'Parcel', icon: PhosphorIconsRegular.package),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 22),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xEB121418),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0x3800E5FF),
                      width: 0.9,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2600E5FF),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppTheme.cyan.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    PhosphorIconsRegular.slidersHorizontal,
                                    size: 16,
                                    color: AppTheme.cyan,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Slot ${slotIndex + 1} Configuration',
                                  style: AppTypography.modalTitle(),
                                ),
                              ],
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: const Icon(
                                PhosphorIconsRegular.x,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customize port, framework signature, and protocol.',
                          style: AppTypography.subtitle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),

                        // Quick Pick Framework Chips
                        Text(
                          'QUICK POPULAR PRESETS',
                          style: AppTypography.monoData(
                            fontSize: 9,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: quickFrameworks.map((fw) {
                            final isCurrentPort =
                                portController.text.trim() ==
                                fw.port.toString();
                            return Bounceable(
                              scaleFactor: 0.95,
                              onTap: () {
                                setDialogState(() {
                                  portController.text = fw.port.toString();
                                  nameController.text = fw.label;
                                  userModifiedName = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentPort
                                      ? AppTheme.cyan.withValues(alpha: 0.15)
                                      : const Color(0xFF0C101A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isCurrentPort
                                        ? AppTheme.cyan
                                        : const Color(0xFF1F283C),
                                    width: isCurrentPort ? 1.0 : 0.7,
                                  ),
                                ),
                                child: Text(
                                  ':${fw.port} ${fw.label}',
                                  style: AppTypography.monoData(
                                    fontSize: 10,
                                    color: isCurrentPort
                                        ? AppTheme.cyan
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Port Field
                        Text(
                          'PORT NUMBER',
                          style: AppTypography.monoData(
                            fontSize: 9.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: portController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(5),
                          ],
                          style: AppTypography.monoData(
                            fontSize: 15,
                            color: Colors.white,
                          ),
                          cursorColor: AppTheme.cyan,
                          onChanged: (val) {
                            final p = int.tryParse(val.trim());
                            if (p != null && !userModifiedName) {
                              final sig = DevPortPreset.fromPortAndSignature(p);
                              if (sig.framework != 'Port $p') {
                                setDialogState(() {
                                  nameController.text = sig.framework;
                                });
                              }
                            }
                          },
                          decoration: InputDecoration(
                            prefixText: ': ',
                            prefixStyle: AppTypography.monoData(
                              fontSize: 15,
                              color: AppTheme.cyan,
                            ),
                            hintText: '5173',
                            hintStyle: AppTypography.monoData(
                              color: AppTheme.textMuted,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0C101A),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B2232),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B2232),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.cyan,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Framework Nickname
                        Text(
                          'FRAMEWORK / NICKNAME',
                          style: AppTypography.monoData(
                            fontSize: 9.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          onChanged: (_) => userModifiedName = true,
                          style: AppTypography.body(fontSize: 14),
                          cursorColor: AppTheme.cyan,
                          decoration: InputDecoration(
                            hintText: 'e.g. Vite, Next.js, Storefront',
                            hintStyle: AppTypography.body(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0C101A),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B2232),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF1B2232),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.cyan,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Protocol Selector Pill
                        Text(
                          'PROTOCOL',
                          style: AppTypography.monoData(
                            fontSize: 9.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Bounceable(
                                scaleFactor: 0.97,
                                onTap: () =>
                                    setDialogState(() => isHttps = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !isHttps
                                        ? AppTheme.cyan.withValues(alpha: 0.15)
                                        : const Color(0xFF0C101A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: !isHttps
                                          ? AppTheme.cyan
                                          : const Color(0xFF1B2232),
                                      width: !isHttps ? 1.2 : 0.8,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'HTTP',
                                    style: AppTypography.monoData(
                                      fontSize: 12,
                                      color: !isHttps
                                          ? AppTheme.cyan
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Bounceable(
                                scaleFactor: 0.97,
                                onTap: () =>
                                    setDialogState(() => isHttps = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isHttps
                                        ? AppTheme.cyan.withValues(alpha: 0.15)
                                        : const Color(0xFF0C101A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isHttps
                                          ? AppTheme.cyan
                                          : const Color(0xFF1B2232),
                                      width: isHttps ? 1.2 : 0.8,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        PhosphorIconsRegular.lockKey,
                                        size: 13,
                                        color: isHttps
                                            ? AppTheme.cyan
                                            : AppTheme.textMuted,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'HTTPS (SSL)',
                                        style: AppTypography.monoData(
                                          fontSize: 12,
                                          color: isHttps
                                              ? AppTheme.cyan
                                              : AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Actions Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_isCustomPinned)
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _resetToAutoAdaptive();
                                },
                                icon: const Icon(
                                  PhosphorIconsRegular.arrowCounterClockwise,
                                  size: 14,
                                  color: AppTheme.textMuted,
                                ),
                                label: Text(
                                  'Reset to Auto',
                                  style: AppTypography.monoData(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: Text(
                                    'Cancel',
                                    style: AppTypography.button(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Bounceable(
                                  onTap: () {
                                    final p = int.tryParse(
                                      portController.text.trim(),
                                    );
                                    if (p == null || p < 1 || p > 65535) {
                                      return;
                                    }

                                    final nickname = nameController.text.trim();
                                    final sig =
                                        DevPortPreset.fromPortAndSignature(
                                          p,
                                          fallbackTitle: nickname,
                                          isHttps: isHttps,
                                          isCustom: true,
                                        );

                                    final updatedPreset = DevPortPreset(
                                      port: p,
                                      framework: nickname.isNotEmpty
                                          ? nickname
                                          : sig.framework,
                                      description: sig.description,
                                      icon: sig.icon,
                                      isHttps: isHttps,
                                      isCustom: true,
                                    );

                                    final updatedList =
                                        List<DevPortPreset>.from(_presets);
                                    updatedList[slotIndex] = updatedPreset;

                                    Navigator.of(ctx).pop();
                                    _saveCustomPresets(updatedList);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cyan,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x3D00E5FF),
                                          blurRadius: 10,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Save & Pin',
                                      style: AppTypography.button(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<SessionItem> get _filteredActivePrototypes {
    return widget.history
        .where((item) {
          final uri = Uri.tryParse(item.url);
          if (uri == null) return true;
          final itemHost = uri.host;
          final itemPort = uri.hasPort
              ? uri.port
              : (uri.scheme == 'https' ? 443 : 80);
          final isMatchingPreset = _presets.any(
            (p) => p.port == itemPort && itemHost == _targetHost,
          );

          if (isMatchingPreset) {
            // Keep if session has custom paths, query params, or controlUrl
            if (uri.pathSegments.isNotEmpty ||
                uri.query.isNotEmpty ||
                item.controlUrl != null) {
              return true;
            }
            final matchingPreset = _presets.firstWhere(
              (p) => p.port == itemPort,
            );
            final defaultTitle =
                '${matchingPreset.framework} (${matchingPreset.port})';
            final isDefaultPresetTitle =
                item.title == defaultTitle ||
                item.title == matchingPreset.framework ||
                item.title == ':${matchingPreset.port}';
            if (isDefaultPresetTitle) {
              return false; // Redundant duplicate! Filter out.
            }
          }
          return true;
        })
        .take(3)
        .toList();
  }
}
