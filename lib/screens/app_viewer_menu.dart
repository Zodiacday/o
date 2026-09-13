// ignore_for_file: invalid_use_of_protected_member

part of 'app_viewer_screen.dart';

/// Helper to generate the exact organic fluid path tethered to the sidebar puck.
@visibleForTesting
class ResponsiveFluidPathBuilder {
  static Path buildPath({
    required Size size,
    required double anchorY,
    required bool isRightSide,
  }) {
    final bodyW = (size.width * 0.78).clamp(280.0, 320.0);
    final bodyH = (size.height * 0.62).clamp(440.0, 500.0);

    final bodyLeft = (size.width - bodyW - 42.0).clamp(16.0, size.width * 0.16);
    final bodyRight = bodyLeft + bodyW;
    final anchorX = size.width;

    final minBodyTop = 56.0;
    final maxBodyTop = size.height - bodyH - 36.0;
    final idealBodyTop = anchorY - (bodyH * 0.45);
    final bodyTop = idealBodyTop.clamp(minBodyTop, maxBodyTop);
    final bodyBottom = bodyTop + bodyH;
    final bodyCenterX = (bodyLeft + bodyRight) / 2;
    final bodyCenterY = (bodyTop + bodyBottom) / 2;

    // Fluid neck connection zone on the right flank (matching 44px radius of bezel hub)
    const hubRadius = FloatingGhostCapsule.quadrantRadius;
    final targetNeckY = anchorY.clamp(bodyTop + 80.0, bodyBottom - 80.0);
    const neckHalfH = 34.0;
    final neckTop = targetNeckY - neckHalfH;
    final neckBottom = targetNeckY + neckHalfH;
    final hipX = bodyRight - 22.0;
    final hipY = bodyBottom - 16.0;
    final shoulderY = bodyTop + 24.0;

    final path = Path();
    // 1. Start at top of the bezel hub on the screen edge
    path.moveTo(anchorX, anchorY - hubRadius);

    // 2. Straight line down along the bezel edge interface
    path.lineTo(anchorX, anchorY + hubRadius);

    // 3. Outward return flare from the bezel hub into the fluid body flank
    path.cubicTo(
      anchorX - 18.0,
      anchorY + hubRadius,
      bodyRight + 20.0,
      neckBottom + 12.0,
      bodyRight,
      neckBottom,
    );

    // 4. Downward monotonic sweep along right flank to bottom-right hip
    path.cubicTo(
      bodyRight - 1.0,
      neckBottom + (hipY - neckBottom) * 0.38,
      bodyRight - 5.0,
      hipY - 12.0,
      hipX,
      hipY,
    );

    // 5. Fluid organic lobes across the base
    path.cubicTo(
      bodyCenterX + 42.0,
      bodyBottom + 8.0,
      bodyCenterX + 16.0,
      bodyBottom + 5.0,
      bodyCenterX,
      bodyBottom + 5.0,
    );
    path.cubicTo(
      bodyCenterX - 20.0,
      bodyBottom + 5.0,
      bodyLeft + 42.0,
      bodyBottom + 12.0,
      bodyLeft + 18.0,
      bodyBottom - 18.0,
    );

    // 6. Organic waist and flank curving up the left side
    path.cubicTo(
      bodyLeft - 8.0,
      bodyBottom - 50.0,
      bodyLeft + 8.0,
      bodyCenterY + 28.0,
      bodyLeft + 6.0,
      bodyCenterY,
    );
    path.cubicTo(
      bodyLeft + 4.0,
      bodyCenterY - 35.0,
      bodyLeft - 8.0,
      bodyTop + 65.0,
      bodyLeft + 18.0,
      bodyTop + 20.0,
    );

    // 7. Sculpted fluid shoulders across the top
    path.cubicTo(
      bodyLeft + 42.0,
      bodyTop - 6.0,
      bodyCenterX - 30.0,
      bodyTop + 2.0,
      bodyCenterX,
      bodyTop + 2.0,
    );
    path.cubicTo(
      bodyCenterX + 35.0,
      bodyTop + 2.0,
      bodyRight - 36.0,
      bodyTop - 4.0,
      bodyRight - 14.0,
      shoulderY,
    );

    // 8. Upper flank monotonic sweep down to neckTop
    path.cubicTo(
      bodyRight - 2.0,
      shoulderY + (neckTop - shoulderY) * 0.45,
      bodyRight,
      neckTop - 12.0,
      bodyRight,
      neckTop,
    );

    // 9. Meet back at top of the bezel hub on the screen edge
    path.cubicTo(
      bodyRight + 20.0,
      neckTop - 12.0,
      anchorX - 18.0,
      anchorY - hubRadius,
      anchorX,
      anchorY - hubRadius,
    );
    path.close();

    // Symmetrically mirror when docked on the left bezel
    if (!isRightSide) {
      final matrix = Matrix4.translationValues(size.width, 0.0, 0.0)
        ..multiply(Matrix4.diagonal3Values(-1.0, 1.0, 1.0));
      return path.transform(matrix.storage);
    }

    return path;
  }

  static Rect getBodyRect({
    required Size size,
    required double anchorY,
    required bool isRightSide,
  }) {
    final bodyW = (size.width * 0.78).clamp(280.0, 320.0);
    final bodyH = (size.height * 0.62).clamp(440.0, 500.0);

    final minBodyTop = 56.0;
    final maxBodyTop = size.height - bodyH - 36.0;
    final idealBodyTop = anchorY - (bodyH * 0.45);
    final bodyTop = idealBodyTop.clamp(minBodyTop, maxBodyTop);

    if (isRightSide) {
      final bodyLeft = (size.width - bodyW - 42.0).clamp(16.0, size.width * 0.16);
      return Rect.fromLTWH(bodyLeft, bodyTop, bodyW, bodyH);
    } else {
      final bodyRight = size.width - (size.width - bodyW - 42.0).clamp(16.0, size.width * 0.16);
      final bodyLeft = bodyRight - bodyW;
      return Rect.fromLTWH(bodyLeft, bodyTop, bodyW, bodyH);
    }
  }
}

typedef _ResponsiveFluidPathBuilder = ResponsiveFluidPathBuilder;

/// CustomClipper that clips child widgets to the responsive fluid shape.
class _ResponsiveFluidMenuClipper extends CustomClipper<Path> {
  final double anchorY;
  final bool isRightSide;

  _ResponsiveFluidMenuClipper({
    required this.anchorY,
    required this.isRightSide,
  });

  @override
  Path getClip(Size size) {
    return _ResponsiveFluidPathBuilder.buildPath(
      size: size,
      anchorY: anchorY,
      isRightSide: isRightSide,
    );
  }

  @override
  bool shouldReclip(covariant _ResponsiveFluidMenuClipper oldClipper) {
    return oldClipper.anchorY != anchorY || oldClipper.isRightSide != isRightSide;
  }
}

/// CustomPainter that strokes the fluid outline with an electric cyan neon glow.
class _ResponsiveFluidMenuPainter extends CustomPainter {
  final double anchorY;
  final bool isRightSide;

  _ResponsiveFluidMenuPainter({
    required this.anchorY,
    required this.isRightSide,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _ResponsiveFluidPathBuilder.buildPath(
      size: size,
      anchorY: anchorY,
      isRightSide: isRightSide,
    );

    // 1. Soft atmospheric outer glow pass
    final outerGlowPaint = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawPath(path, outerGlowPaint);

    // 2. Focused vibrant cyan mid-pass
    final midGlowPaint = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(path, midGlowPaint);

    // 3. Crisp, bright electric cyan hairline edge
    final linePaint = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // 4. Liquid-glass inner specular highlight along top shoulder
    final bodyRect = _ResponsiveFluidPathBuilder.getBodyRect(
      size: size,
      anchorY: anchorY,
      isRightSide: isRightSide,
    );
    final highlightPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(bodyRect.center.dx, bodyRect.top),
        Offset(bodyRect.center.dx, bodyRect.top + 75),
        [
          Colors.white.withValues(alpha: 0.60),
          AppTheme.cyan.withValues(alpha: 0.20),
          Colors.transparent,
        ],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _ResponsiveFluidMenuPainter oldDelegate) {
    return oldDelegate.anchorY != anchorY || oldDelegate.isRightSide != isRightSide;
  }
}

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

    final bloomAlignment = _capsuleIsRightSide
        ? Alignment(1.0, ((anchorY / screenH) * 2.0 - 1.0).clamp(-1.0, 1.0))
        : Alignment(-1.0, ((anchorY / screenH) * 2.0 - 1.0).clamp(-1.0, 1.0));

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_isMenuOpen,
        child: AnimatedOpacity(
          opacity: _isMenuOpen ? 1 : 0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (details) {
              final path = _ResponsiveFluidPathBuilder.buildPath(
                size: mq.size,
                anchorY: anchorY,
                isRightSide: _capsuleIsRightSide,
              );
              // Absorb taps inside the fluid sculpture (neck, body, or lobes)
              if (path.contains(details.localPosition)) return;
              _closeMenu();
            },
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.60),
              child: AnimatedSlide(
                offset: _isMenuOpen
                    ? Offset.zero
                    : Offset(_capsuleIsRightSide ? 0.05 : -0.05, 0.0),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: AnimatedScale(
                  scale: _isMenuOpen ? 1.0 : 0.05,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  alignment: bloomAlignment,
                  child: _buildConnectedFluidMenu(
                    anchorY: anchorY,
                    isRightSide: _capsuleIsRightSide,
                    size: mq.size,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedFluidMenu({
    required double anchorY,
    required bool isRightSide,
    required Size size,
  }) {
    final bodyRect = _ResponsiveFluidPathBuilder.getBodyRect(
      size: size,
      anchorY: anchorY,
      isRightSide: isRightSide,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Fluid outline with luminous electric cyan glow
        CustomPaint(
          size: size,
          painter: _ResponsiveFluidMenuPainter(
            anchorY: anchorY,
            isRightSide: isRightSide,
          ),
        ),

        // 2. Celestial oil painting background clipped to the exact fluid shape
        ClipPath(
          clipper: _ResponsiveFluidMenuClipper(
            anchorY: anchorY,
            isRightSide: isRightSide,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Celestial textured oil painting
              Image.asset(
                'assets/celestial_menu_bg.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),

              // Deep ambient obsidian vignette overlay for crystal-clear readability
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xD8080C14),
                      const Color(0xB8090E1A),
                      const Color(0xE8080C14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Active Foreground Docking Hub physically bonded to the fluid neck
        Positioned(
          top: anchorY - FloatingGhostCapsule.quadrantRadius,
          right: isRightSide ? 0 : null,
          left: !isRightSide ? 0 : null,
          child: _buildActiveDockingHub(isRightSide),
        ),

        // 4. Interactive content positioned inside the fluid body
        Positioned(
          left: bodyRect.left,
          top: bodyRect.top,
          width: bodyRect.width,
          height: bodyRect.height,
          child: GestureDetector(
            onTap: () {}, // Trap taps inside menu body
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: _buildFluidMenuContent(),
            ),
          ),
        ),
      ],
    );
  }

  /// Active Foreground Docking Hub displayed right at the screen edge
  Widget _buildActiveDockingHub(bool isRightSide) {
    const hubRadius = FloatingGhostCapsule.quadrantRadius;
    const hubHeight = FloatingGhostCapsule.quadrantHeight;

    final borderRadius = isRightSide
        ? const BorderRadius.only(
            topLeft: Radius.circular(hubRadius),
            bottomLeft: Radius.circular(hubRadius),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(hubRadius),
            bottomRight: Radius.circular(hubRadius),
          );

    return GestureDetector(
      key: const Key('active_fluid_docking_hub'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        _closeMenu();
      },
      child: Tooltip(
        message: 'Close Dev Menu',
        child: Container(
          width: hubRadius,
          height: hubHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF0B0E17),
            borderRadius: borderRadius,
            border: Border.all(
              color: AppTheme.cyan,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.70),
                blurRadius: 14,
                offset: Offset(isRightSide ? -3 : 3, 3),
              ),
              BoxShadow(
                color: AppTheme.cyan.withValues(alpha: 0.40),
                blurRadius: 14,
                spreadRadius: 1.0,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isRightSide
                  ? PhosphorIconsRegular.caretRight
                  : PhosphorIconsRegular.caretLeft,
              size: 20,
              color: AppTheme.cyan,
              shadows: [
                Shadow(
                  color: AppTheme.cyan.withValues(alpha: 0.85),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFluidMenuContent() {
    final isCliConnected = _diagnosticsChannel?.isConnected ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
        // 1. PreviewPort Header with official branding & close icon
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/previewport-logo-transparent.png',
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PreviewPort',
                      style: AppTypography.displayHero(
                        color: Colors.white,
                      ).copyWith(fontSize: 18, letterSpacing: -0.2),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _closeMenu,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        PhosphorIconsRegular.x,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _dynamicTitle ?? 'Flutter App',
                    style: AppTypography.subtitle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCliConnected
                        ? const Color(0x2400F2FE)
                        : const Color(0x18FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCliConnected
                          ? AppTheme.cyan.withValues(alpha: 0.50)
                          : Colors.white24,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isCliConnected ? AppTheme.cyan : AppTheme.warning,
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (isCliConnected)
                              BoxShadow(
                                color: AppTheme.cyan.withValues(alpha: 0.9),
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isCliConnected ? 'CLI SYNCED' : 'STANDALONE',
                        style: AppTypography.monoData(
                          color: isCliConnected ? AppTheme.cyan : Colors.white70,
                          fontSize: 9,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // 2. Dual Tactile Hero Action Pills (Hot Reload & Restart)
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _triggerRemoteReload();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x2200F2FE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.cyan.withValues(alpha: 0.95),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.cyan.withValues(alpha: 0.30),
                          blurRadius: 12,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          PhosphorIconsRegular.arrowClockwise,
                          size: 16,
                          color: AppTheme.cyan,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'HOT RELOAD',
                          style: AppTypography.button(
                            fontSize: 11.5,
                            color: AppTheme.cyan,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _triggerRemoteRestart();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x33101520),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          PhosphorIconsRegular.arrowsClockwise,
                          size: 15,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'RESTART',
                          style: AppTypography.button(
                            fontSize: 11,
                            color: Colors.white70,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // 3. Viewport Switcher Card
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openViewportSwitcher,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x33101520),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.cyan.withValues(alpha: 0.40),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedDevice.icon,
                    size: 18,
                    color: AppTheme.cyan,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VIEWPORT SWITCHER',
                          style: AppTypography.sectionHud(
                            color: AppTheme.textSecondary,
                          ).copyWith(fontSize: 9.5),
                        ),
                        Text(
                          _selectedDevice.name,
                          style: AppTypography.itemTitle(
                            fontSize: 13.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    PhosphorIconsRegular.caretDown,
                    size: 14,
                    color: AppTheme.cyan,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 4. Compact Logs & Cache Row
        Row(
          children: [
            // Logs Card
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openMiniTerminal,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0x33101520),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          PhosphorIconsRegular.terminalWindow,
                          size: 17,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Logs',
                            style: AppTypography.button(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: _terminalLogs.isNotEmpty
                                ? const Color(0x2A00F2FE)
                                : const Color(0x18FFFFFF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_terminalLogs.length}',
                            style: AppTypography.monoData(
                              color: _terminalLogs.isNotEmpty
                                  ? AppTheme.cyan
                                  : AppTheme.textMuted,
                              fontSize: 9.5,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Clear Cache Card
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0x33101520),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          PhosphorIconsRegular.trash,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Clear Cache',
                          style: AppTypography.button(
                            fontSize: 11.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // 5. Exit to Scanner Footer
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.heavyImpact();
              _closeMenu();
              _showExitDialog();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0x18FF4D4D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0x44FF4D4D),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    PhosphorIconsRegular.qrCode,
                    size: 15,
                    color: AppTheme.danger,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'EXIT TO SCANNER',
                    style: AppTypography.button(
                      fontSize: 11,
                      color: AppTheme.danger,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),
);
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
