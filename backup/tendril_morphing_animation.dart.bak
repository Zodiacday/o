import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import 'dev_menu_content.dart';

/// Driver interface for programmatic external control of the liquid seed.
abstract class LiquidDevControlDriver {
  bool get isOpen;
  Future<void> openMenu();
  Future<void> dismiss();
  Future<void> openSatellites();
  Future<void> toggle();
}

/// External controller for [LiquidSidebarSeed] (e.g. shake detector, hotkeys).
class LiquidDevControlController extends ChangeNotifier {
  LiquidDevControlDriver? _driver;

  bool get isOpen => _driver?.isOpen ?? false;

  void attach(LiquidDevControlDriver driver) {
    _driver = driver;
    notifyListeners();
  }

  void detach(LiquidDevControlDriver driver) {
    if (_driver == driver) {
      _driver = null;
      notifyListeners();
    }
  }

  Future<void> openMenu() async => _driver?.openMenu();
  Future<void> dismiss() async => _driver?.dismiss();
  Future<void> openSatellites() async => _driver?.openSatellites();
  Future<void> toggle() async => _driver?.toggle();
}

/// One continuous liquid surface:
/// [Seed] ══tendril 1══> [Reload Circle]
///        ══tendril 2══> [Menu Circle] ══tendril 3══> [Menu Card]
class LiquidSidebarSeed extends StatefulWidget {
  final LiquidDevControlController? controller;
  final String? title;
  final bool isCliConnected;
  final int terminalLogCount;
  final String selectedDeviceName;
  final IconData selectedDeviceIcon;
  final VoidCallback? onHotReload;
  final VoidCallback? onRestart;
  final VoidCallback? onOpenViewportSwitcher;
  final VoidCallback? onOpenTerminal;
  final VoidCallback? onClearCache;
  final VoidCallback? onExit;

  const LiquidSidebarSeed({
    super.key,
    this.controller,
    this.title,
    this.isCliConnected = true,
    this.terminalLogCount = 2,
    this.selectedDeviceName = 'iPhone 16 Pro',
    this.selectedDeviceIcon = Icons.phone_iphone,
    this.onHotReload,
    this.onRestart,
    this.onOpenViewportSwitcher,
    this.onOpenTerminal,
    this.onClearCache,
    this.onExit,
  });

  @override
  State<LiquidSidebarSeed> createState() => _LiquidSidebarSeedState();
}

class _LiquidSidebarSeedState extends State<LiquidSidebarSeed>
    with TickerProviderStateMixin
    implements LiquidDevControlDriver {
  static const _positionKey = 'liquid_sidebar_seed_dy';
  static const _sideKey = 'liquid_sidebar_seed_is_right';
  static const _seedSize = Size(24.0, 84.0);
  static const _circleSize = 52.0;
  static const _lineHeight = 9.9;
  static const _edgeMargin = 12.0;
  static const _circleInset = 88.0;
  static const _circleSeparation = 70.0;
  static const _blenderSmoothness = 14.0;

  late final AnimationController _morph;
  late final AnimationController _menuMorph;
  late final AnimationController _reloadSpin;
  Timer? _idleTimer;
  double _dy = 0.65;
  bool _isRightSide = true;
  bool _open = false;
  bool _menuOpen = false;
  bool _isIdle = false;
  bool _pressedReload = false;
  bool _pressedMenu = false;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(this);
    unawaited(LiquidGlassShaders.ensureLoaded());
    _morph = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 500),
    )..addListener(() => setState(() {}));

    _menuMorph = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
      reverseDuration: const Duration(milliseconds: 360),
    )..addListener(() => setState(() {}));

    _reloadSpin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(() => setState(() {}));

    _restorePosition();
    _startIdleTimer();
  }

  @override
  void didUpdateWidget(covariant LiquidSidebarSeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach(this);
      widget.controller?.attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(this);
    _idleTimer?.cancel();
    _reloadSpin.dispose();
    _menuMorph.dispose();
    _morph.dispose();
    super.dispose();
  }

  // --- LiquidDevControlDriver implementation ---
  @override
  bool get isOpen => _open || _menuOpen;

  @override
  Future<void> openSatellites() async {
    if (_open) return;
    _idleTimer?.cancel();
    if (_isIdle) setState(() => _isIdle = false);
    setState(() => _open = true);
    unawaited(_morph.forward());
  }

  @override
  Future<void> openMenu() async {
    _idleTimer?.cancel();
    if (_isIdle) setState(() => _isIdle = false);
    if (!_open) {
      setState(() => _open = true);
      _morph.forward();
    }
    if (!_menuOpen) {
      setState(() => _menuOpen = true);
      unawaited(_menuMorph.forward());
    }
  }

  @override
  Future<void> dismiss() async {
    _idleTimer?.cancel();
    if (_menuOpen) {
      setState(() => _menuOpen = false);
      _menuMorph.reverse();
    }
    if (_open) {
      setState(() => _open = false);
      _morph.reverse().then((_) {
        if (mounted && !_open) _startIdleTimer();
      });
    }
  }

  @override
  Future<void> toggle() async {
    _toggle();
  }
  // ----------------------------------------------

  void _startIdleTimer() {
    _idleTimer?.cancel();
    if (!_open && !_menuOpen && mounted) {
      _idleTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted &&
            !_open &&
            !_menuOpen &&
            !_morph.isAnimating &&
            !_menuMorph.isAnimating) {
          setState(() => _isIdle = true);
        }
      });
    }
  }

  void _wakeUp() {
    if (_isIdle) {
      setState(() => _isIdle = false);
    }
    _startIdleTimer();
  }

  Future<void> _restorePosition() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _dy = (prefs.getDouble(_positionKey) ?? _dy).clamp(0, 1);
      _isRightSide = prefs.getBool(_sideKey) ?? _isRightSide;
    });
  }

  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_positionKey, _dy);
    await prefs.setBool(_sideKey, _isRightSide);
  }

  void _handleHotReload() {
    if (_isReloading) return;
    HapticFeedback.mediumImpact();
    setState(() => _isReloading = true);
    _reloadSpin.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() => _isReloading = false);
      }
    });
    widget.onHotReload?.call();
  }

  void _toggle() {
    if (_morph.isAnimating || _menuMorph.isAnimating) return;
    _idleTimer?.cancel();
    if (_isIdle) setState(() => _isIdle = false);

    if (_menuOpen) {
      _closeMenuCard();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _open = !_open);
    if (_open) {
      _morph.forward();
    } else {
      _morph.reverse().then((_) {
        if (mounted && !_open) _startIdleTimer();
      });
    }
  }

  void _openMenuCard() {
    if (_menuMorph.isAnimating) return;
    HapticFeedback.mediumImpact();
    setState(() => _menuOpen = true);
    _menuMorph.forward();
  }

  void _closeMenuCard() {
    if (_menuMorph.isAnimating) return;
    HapticFeedback.lightImpact();
    setState(() => _menuOpen = false);
    _menuMorph.reverse().then((_) {
      if (mounted && !_open) _startIdleTimer();
    });
  }

  void _runAndClose(VoidCallback? action) {
    _closeMenuCard();
    action?.call();
  }

  double _phase(double value, double begin, double end) {
    final t = ((value - begin) / (end - begin)).clamp(0.0, 1.0);
    return Curves.easeInOutCubicEmphasized.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topLimit = mq.padding.top + 16;
    final bottomLimit =
        mq.size.height - mq.padding.bottom - 16 - _seedSize.height;
    final travel = (bottomLimit - topLimit).clamp(0.0, double.infinity);
    final seedTop = topLimit + travel * _dy;

    final seedX = _isRightSide
        ? mq.size.width - _seedSize.width - _edgeMargin
        : _edgeMargin;
    final seedRect = Rect.fromLTWH(
      seedX,
      seedTop,
      _seedSize.width,
      _seedSize.height,
    );

    final targetCenterX =
        _isRightSide ? mq.size.width - _circleInset : _circleInset;
    final minCircleCenterY = mq.padding.top + 16 + _circleSize / 2;
    final maxCircleCenterY =
        mq.size.height - mq.padding.bottom - 16 - _circleSize / 2;

    final nominalReloadY = seedRect.center.dy - _circleSeparation / 2;
    final nominalMenuY = seedRect.center.dy + _circleSeparation / 2;

    final reloadTarget = Offset(
      targetCenterX,
      nominalReloadY.clamp(
          minCircleCenterY, maxCircleCenterY - _circleSeparation),
    );
    final menuTarget = Offset(
      targetCenterX,
      nominalMenuY.clamp(
          minCircleCenterY + _circleSeparation, maxCircleCenterY),
    );
    final reservoirX =
        _isRightSide ? seedRect.center.dx + 2.0 : seedRect.center.dx - 2.0;

    // ==========================================
    // Phase 1: Tendrils 1 & 2 (Seed to Satellites)
    // ==========================================
    final reloadLineProgress = _phase(_morph.value, 0.00, 0.48);
    final menuLineProgress = _phase(_morph.value, 0.06, 0.54);

    final reloadCirclePhase = _phase(_morph.value, 0.44, 0.94);
    final menuCirclePhase = _phase(_morph.value, 0.50, 1.00);

    final reloadBloom = Curves.easeOutBack.transform(reloadCirclePhase);
    final menuBloom = Curves.easeOutBack.transform(menuCirclePhase);

    final reloadRadius =
        lerpDouble(_lineHeight / 2, _circleSize / 2, reloadBloom)!;
    final menuRadius =
        lerpDouble(_lineHeight / 2, _circleSize / 2, menuBloom)!;

    final reloadPulseScale = _isReloading
        ? 1.0 + (math.sin(_reloadSpin.value * math.pi) * 0.14)
        : 1.0;
    final reloadSize =
        (reloadRadius * 2) * (_pressedReload ? 0.92 : 1.0) * reloadPulseScale;
    final menuSize = (menuRadius * 2) * (_pressedMenu ? 0.92 : 1.0);

    final reloadPinch = math.sin(reloadLineProgress * math.pi) * 1.5;
    final reloadLineHeight = _lineHeight - reloadPinch;

    final menuPinch = math.sin(menuLineProgress * math.pi) * 1.5;
    final menuLineHeight = _lineHeight - menuPinch;

    final reloadTipX =
        lerpDouble(reservoirX, targetCenterX, reloadLineProgress)!;
    final menuTipX =
        lerpDouble(reservoirX, targetCenterX, menuLineProgress)!;

    final double reloadLineA;
    final double reloadLineB;
    if (_isRightSide) {
      final tip = lerpDouble(
        reloadTipX,
        targetCenterX + reloadRadius - 4.0,
        reloadCirclePhase,
      )!;
      reloadLineA = math.min(tip, reservoirX - 0.5);
      reloadLineB = reservoirX;
    } else {
      final tip = lerpDouble(
        reloadTipX,
        targetCenterX - reloadRadius + 4.0,
        reloadCirclePhase,
      )!;
      reloadLineA = reservoirX;
      reloadLineB = math.max(tip, reservoirX + 0.5);
    }

    final reloadLine = Rect.fromLTRB(
      reloadLineA,
      reloadTarget.dy - reloadLineHeight / 2,
      reloadLineB,
      reloadTarget.dy + reloadLineHeight / 2,
    );

    final double menuLineA;
    final double menuLineB;
    if (_isRightSide) {
      final tip = lerpDouble(
        menuTipX,
        targetCenterX + menuRadius - 4.0,
        menuCirclePhase,
      )!;
      menuLineA = math.min(tip, reservoirX - 0.5);
      menuLineB = reservoirX;
    } else {
      final tip = lerpDouble(
        menuTipX,
        targetCenterX - menuRadius + 4.0,
        menuCirclePhase,
      )!;
      menuLineA = reservoirX;
      menuLineB = math.max(tip, reservoirX + 0.5);
    }

    final menuLine = Rect.fromLTRB(
      menuLineA,
      menuTarget.dy - menuLineHeight / 2,
      menuLineB,
      menuTarget.dy + menuLineHeight / 2,
    );

    final reloadCircle = Rect.fromCenter(
      center: Offset(reloadTipX, reloadTarget.dy),
      width: reloadSize,
      height: reloadSize,
    );

    final menuCircle = Rect.fromCenter(
      center: Offset(menuTipX, menuTarget.dy),
      width: menuSize,
      height: menuSize,
    );

    // ==========================================
    // Phase 2: Tendril 3 & Adaptive Menu Card Extrusion
    // ==========================================
    const menuCardWidth = 150.0;
    const menuCardHeight = 356.0;

    final cardMinCenterY = topLimit + menuCardHeight / 2;
    final cardMaxCenterY =
        (mq.size.height - mq.padding.bottom - 16 - menuCardHeight / 2);

    final menuCardCenterY = (cardMinCenterY <= cardMaxCenterY)
        ? menuTarget.dy.clamp(cardMinCenterY, cardMaxCenterY)
        : (topLimit + (mq.size.height - mq.padding.bottom - 16)) / 2;

    final targetCardTop = menuCardCenterY - menuCardHeight / 2;
    final targetCardBottom = menuCardCenterY + menuCardHeight / 2;

    final lineY =
        menuTarget.dy.clamp(targetCardTop + 24.0, targetCardBottom - 24.0);

    const connectingLineLength = 28.0;

    // Sub-phase 2a: Tendril 3 shoots outward from Menu Circle (0.00 -> 0.42)
    final cardLineProgress = _phase(_menuMorph.value, 0.00, 0.42);
    final cardPinch = math.sin(cardLineProgress * math.pi) * 1.5;
    final cardLineHeight = _lineHeight - cardPinch;

    final cardBloomProgress = _phase(_menuMorph.value, 0.38, 1.00);
    final cardBloom = Curves.easeOutBack.transform(cardBloomProgress);

    final currentCardTop =
        lerpDouble(lineY - _lineHeight / 2, targetCardTop, cardBloom)!;
    final currentCardBottom =
        lerpDouble(lineY + _lineHeight / 2, targetCardBottom, cardBloom)!;
    final currentCardCornerRadius =
        lerpDouble(_lineHeight / 2, 22.0, cardBloom)!;
    final currentCardWidth =
        lerpDouble(_lineHeight, menuCardWidth, cardBloom)!;

    final Rect cardConnectorLine;
    final double currentCardLeft;
    final double currentCardRight;

    if (_isRightSide) {
      final menuCircleLeft = menuTarget.dx - _circleSize / 2;
      final cardRestingRight = menuCircleLeft - connectingLineLength;
      final lineOriginX = menuTarget.dx - 12.0;
      final lineTipX =
          lerpDouble(lineOriginX, cardRestingRight, cardLineProgress)!;

      cardConnectorLine = Rect.fromLTRB(
        lineTipX,
        lineY - cardLineHeight / 2,
        lineOriginX,
        lineY + cardLineHeight / 2,
      );

      currentCardRight =
          lerpDouble(lineTipX, cardRestingRight + 2.0, cardBloomProgress)!;
      currentCardLeft = currentCardRight - currentCardWidth;
    } else {
      final menuCircleRight = menuTarget.dx + _circleSize / 2;
      final cardRestingLeft = menuCircleRight + connectingLineLength;
      final lineOriginX = menuTarget.dx + 12.0;
      final lineTipX =
          lerpDouble(lineOriginX, cardRestingLeft, cardLineProgress)!;

      cardConnectorLine = Rect.fromLTRB(
        lineOriginX,
        lineY - cardLineHeight / 2,
        lineTipX,
        lineY + cardLineHeight / 2,
      );

      currentCardLeft =
          lerpDouble(lineTipX, cardRestingLeft - 2.0, cardBloomProgress)!;
      currentCardRight = currentCardLeft + currentCardWidth;
    }

    final currentCardRect = Rect.fromLTRB(
      currentCardLeft,
      currentCardTop,
      currentCardRight,
      currentCardBottom,
    );

    // Dynamic theme signaling: AppTheme.cyan (connected) vs AppTheme.warning (disconnected)
    final statusColor =
        widget.isCliConnected ? AppTheme.cyan : AppTheme.warning;
    final glassColor = widget.isCliConnected
        ? AppTheme.cyan.withValues(alpha: 0.35)
        : AppTheme.warning.withValues(alpha: 0.35);
    final rimLightColor = widget.isCliConnected
        ? Color.lerp(Colors.white, AppTheme.cyan, 0.40)!
        : Color.lerp(Colors.white, AppTheme.warning, 0.45)!;

    // Content inside the menu card lens: cross-fades in once card is formed
    Widget? cardContent;
    if (_menuMorph.value > 0.55) {
      final contentOpacity = Curves.easeOut
          .transform(((_menuMorph.value - 0.55) / 0.45).clamp(0.0, 1.0));
      cardContent = Opacity(
        opacity: contentOpacity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isCliConnected
                  ? const [
                      Color(0x2800E5FF),
                      Color(0x45081E32),
                    ]
                  : const [
                      Color(0x28F59E0B),
                      Color(0x45281808),
                    ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              DevMenuContent(
                title: widget.title,
                isCliConnected: widget.isCliConnected,
                terminalLogCount: widget.terminalLogCount,
                selectedDeviceName: widget.selectedDeviceName,
                selectedDeviceIcon: widget.selectedDeviceIcon,
                onHotReload: () {
                  _handleHotReload();
                  _closeMenuCard();
                },
                onRestart: () => _runAndClose(widget.onRestart),
                onOpenViewportSwitcher: () =>
                    _runAndClose(widget.onOpenViewportSwitcher),
                onOpenTerminal: () => _runAndClose(widget.onOpenTerminal),
                onClearCache: () => _runAndClose(widget.onClearCache),
                onExit: () => _runAndClose(widget.onExit),
              ),
              Positioned(
                right: 0,
                top: -6,
                child: GestureDetector(
                  key: const Key('liquid_menu_close_btn'),
                  onTap: _closeMenuCard,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      PhosphorIconsRegular.x,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Positioned.fill(
      child: Stack(
        children: [
          // Dismiss layer for expanded menu card
          if (_menuMorph.value > 0)
            Positioned.fill(
              child: GestureDetector(
                key: const Key('native_glass_dismiss_layer'),
                behavior: HitTestBehavior.opaque,
                onTap: _closeMenuCard,
                child: ColoredBox(
                  color: Colors.black
                      .withValues(alpha: 0.38 * _menuMorph.value),
                ),
              ),
            ),

          // Dismiss layer for satellite mode
          if (_morph.value > 0 && _menuMorph.value == 0)
            Positioned.fill(
              child: GestureDetector(
                key: const Key('liquid_satellite_dismiss_layer'),
                behavior: HitTestBehavior.opaque,
                onTap: _open && !_morph.isAnimating ? _toggle : null,
              ),
            ),

          AnimatedOpacity(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            opacity: (_isIdle &&
                    !_open &&
                    !_menuOpen &&
                    _morph.value == 0)
                ? 0.70
                : 1.0,
            child: LiquidGlassBlender(
              key: const Key('liquid_reservoir_blender'),
              smoothness: _blenderSmoothness,
              style: LiquidGlassStyle(
                shape: LiquidGlassShape.continuousRoundedRectangle(
                  lightDirection: 135.0,
                  lightIntensity: 1.7,
                  lightColor: rimLightColor,
                  borderWidth: 1.4,
                ),
                appearance: LiquidGlassAppearance(
                  blur: const LiquidGlassBlur(sigmaX: 20.0, sigmaY: 20.0),
                  saturation: widget.isCliConnected ? 1.25 : 1.10,
                  color: glassColor,
                ),
                refraction: const LiquidGlassRefraction(
                  magnification: 1.05,
                  chromaticAberration: 0.024,
                ),
              ),
              child: Stack(
                children: [
                  // 1. Seed lens (painted with luminous fluid core)
                  _lens(
                    seedRect,
                    const Key('liquid_sidebar_seed_lens'),
                    shape: LiquidGlassShape.roundedRectangle(
                      cornerRadius: 50.0,
                      lightColor: rimLightColor,
                    ),
                    content: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50.0),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            statusColor.withValues(alpha: 0.90),
                            statusColor.withValues(alpha: 0.55),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.45),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Connector line 1 (Seed -> Reload)
                  _lens(
                    reloadLine,
                    const Key('liquid_reload_connector'),
                    shape: LiquidGlassShape.roundedRectangle(
                      cornerRadius: 0,
                      lightColor: rimLightColor,
                    ),
                  ),

                  // 3. Connector line 2 (Seed -> Menu)
                  _lens(
                    menuLine,
                    const Key('liquid_menu_connector'),
                    shape: LiquidGlassShape.roundedRectangle(
                      cornerRadius: 0,
                      lightColor: rimLightColor,
                    ),
                  ),

                  // 4. Reload satellite circle
                  _lens(
                    reloadCircle,
                    const Key('liquid_reload_lens'),
                    shape: LiquidGlassShape.continuousRoundedRectangle(
                      cornerRadius: 26,
                      lightColor: rimLightColor,
                      lightIntensity: _isReloading
                          ? 1.7 + (math.sin(_reloadSpin.value * math.pi) * 1.1)
                          : 1.7,
                    ),
                    content: Opacity(
                      opacity: _phase(reloadCirclePhase, 0.65, 1.0),
                      child: Center(
                        child: Transform.rotate(
                          angle: _reloadSpin.value * 2 * math.pi,
                          child: Icon(
                            PhosphorIconsRegular.arrowClockwise,
                            color: statusColor,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 5. Menu satellite circle
                  _lens(
                    menuCircle,
                    const Key('liquid_menu_lens'),
                    shape: LiquidGlassShape.continuousRoundedRectangle(
                      cornerRadius: 26,
                      lightColor: rimLightColor,
                    ),
                    icon: PhosphorIconsRegular.slidersHorizontal,
                    iconOpacity: menuCirclePhase,
                    iconColor: statusColor,
                  ),

                  // 6. Connector line 3 (Menu Circle -> Menu Card)
                  if (_menuMorph.value > 0)
                    _lens(
                      cardConnectorLine,
                      const Key('liquid_menu_card_connector'),
                      shape: LiquidGlassShape.roundedRectangle(
                        cornerRadius: 0,
                        lightColor: rimLightColor,
                      ),
                    ),

                  // 7. Full Menu Card (Blooms at the tip of Line 3)
                  if (_menuMorph.value > 0)
                    _lens(
                      currentCardRect,
                      const Key('liquid_menu_card_lens'),
                      shape: LiquidGlassShape.continuousRoundedRectangle(
                        cornerRadius: currentCardCornerRadius,
                        lightColor: rimLightColor,
                      ),
                      content: cardContent,
                    ),
                ],
              ),
            ),
          ),

          // Tap and drag detector on the floating seed
          if (_menuMorph.value == 0)
            Positioned.fromRect(
              rect: seedRect.inflate(8),
              child: GestureDetector(
                key: const Key('liquid_sidebar_seed'),
                behavior: HitTestBehavior.opaque,
                onTap: _toggle,
                onPanStart: (_) => _wakeUp(),
                onPanUpdate: _morph.value > 0
                    ? null
                    : (details) {
                        _wakeUp();
                        if (travel <= 0) return;
                        setState(() {
                          _dy = (_dy + details.delta.dy / travel).clamp(0, 1);
                          if (details.globalPosition.dx <
                              mq.size.width * 0.4) {
                            _isRightSide = false;
                          } else if (details.globalPosition.dx >
                              mq.size.width * 0.6) {
                            _isRightSide = true;
                          }
                        });
                      },
                onPanEnd: _morph.value > 0
                    ? null
                    : (_) {
                        _wakeUp();
                        HapticFeedback.lightImpact();
                        _savePosition();
                      },
              ),
            ),

          // Hit targets for the satellite circles
          if (_open && !_morph.isAnimating && _menuMorph.value == 0) ...[
            _hit(
              reloadCircle,
              const Key('liquid_reload_circle'),
              () {
                _handleHotReload();
                _toggle();
              },
              onHighlight: (val) => setState(() => _pressedReload = val),
            ),
            _hit(
              menuCircle,
              const Key('liquid_menu_circle'),
              _openMenuCard,
              onHighlight: (val) => setState(() => _pressedMenu = val),
            ),
          ],

          Positioned.fromRect(
            key: const Key('liquid_sidebar_seed_position'),
            rect: seedRect,
            child: const IgnorePointer(),
          ),
        ],
      ),
    );
  }

  Widget _lens(
    Rect rect,
    Key key, {
    LiquidGlassShape? shape,
    Widget? content,
    IconData? icon,
    double iconOpacity = 0,
    Color? iconColor,
  }) {
    final statusColor =
        widget.isCliConnected ? AppTheme.cyan : AppTheme.warning;
    final rimLightColor = widget.isCliConnected
        ? Color.lerp(Colors.white, AppTheme.cyan, 0.40)!
        : Color.lerp(Colors.white, AppTheme.warning, 0.45)!;

    return Positioned.fromRect(
      key: key,
      rect: rect,
      child: LiquidGlassLens(
        style: LiquidGlassStyle(
          shape: shape ??
              LiquidGlassShape.continuousRoundedRectangle(
                lightColor: rimLightColor,
              ),
        ),
        child: content ??
            (icon == null
                ? const SizedBox.expand()
                : Opacity(
                    opacity: _phase(iconOpacity, 0.65, 1.0),
                    child: Icon(
                      icon,
                      color: iconColor ?? statusColor,
                      size: 19,
                    ),
                  )),
      ),
    );
  }

  Widget _hit(
    Rect rect,
    Key key,
    VoidCallback tap, {
    required ValueChanged<bool> onHighlight,
  }) =>
      Positioned.fromRect(
        key: key,
        rect: rect,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            HapticFeedback.lightImpact();
            onHighlight(true);
          },
          onTapUp: (_) => onHighlight(false),
          onTapCancel: () => onHighlight(false),
          onTap: tap,
        ),
      );
}
