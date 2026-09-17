import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import 'dev_menu_content.dart';

/// Driver interface for programmatic external control of the dev seed.
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

/// A clean, minimal developer HUD sidebar handle docked to the bezel edge.
///
/// Single-tap opens the complete Dev Menu card directly at the center of the screen
/// with a smooth scale/fade animation and dark scrim backdrop.
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
    with SingleTickerProviderStateMixin
    implements LiquidDevControlDriver {
  static const _positionKey = 'liquid_sidebar_seed_dy';
  static const _sideKey = 'liquid_sidebar_seed_is_right';
  static const _seedSize = Size(20.0, 72.0);
  static const _edgeMargin = 12.0;

  late final AnimationController _menuAnim;
  Timer? _idleTimer;
  double _dy = 0.65;
  bool _isRightSide = true;
  bool _isIdle = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(this);
    _menuAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
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
    _menuAnim.dispose();
    super.dispose();
  }

  // --- LiquidDevControlDriver implementation ---
  @override
  bool get isOpen => _menuAnim.value > 0;

  @override
  Future<void> openSatellites() async => openMenu();

  @override
  Future<void> openMenu() async {
    _idleTimer?.cancel();
    if (_isIdle) setState(() => _isIdle = false);
    _menuAnim.forward();
  }

  @override
  Future<void> dismiss() async {
    _idleTimer?.cancel();
    _menuAnim.reverse();
    if (mounted) _startIdleTimer();
  }

  @override
  Future<void> toggle() async {
    if (_menuAnim.value > 0.5) {
      dismiss();
    } else {
      openMenu();
    }
  }
  // ----------------------------------------------

  void _startIdleTimer() {
    _idleTimer?.cancel();
    if (_menuAnim.value == 0 && mounted) {
      _idleTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted && _menuAnim.value == 0) {
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
    HapticFeedback.mediumImpact();
    widget.onHotReload?.call();
  }

  void _runAndClose(VoidCallback? action) {
    dismiss();
    action?.call();
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

    final statusColor =
        widget.isCliConnected ? AppTheme.cyan : AppTheme.warning;

    final isMenuOpen = _menuAnim.value > 0;

    return Positioned.fill(
      child: Stack(
        children: [
          // 1. Dark Backdrop Scrim (Dismiss layer on tap)
          if (isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                key: const Key('native_glass_dismiss_layer'),
                behavior: HitTestBehavior.opaque,
                onTap: dismiss,
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.55 * _menuAnim.value),
                ),
              ),
            ),

          // 2. Centered Dev Menu Card Modal
          if (isMenuOpen)
            Center(
              child: Transform.scale(
                scale: 0.88 +
                    (0.12 * Curves.easeOutBack.transform(_menuAnim.value)),
                child: Opacity(
                  opacity: _menuAnim.value.clamp(0.0, 1.0),
                  child: Container(
                    key: const Key('liquid_menu_card_lens'),
                    width: math.min(mq.size.width - 40.0, 330.0),
                    constraints: BoxConstraints(
                      maxHeight: mq.size.height -
                          mq.padding.top -
                          mq.padding.bottom -
                          48.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1420),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.85),
                          blurRadius: 36,
                          spreadRadius: 4,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.22),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
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
                            dismiss();
                          },
                          onRestart: () => _runAndClose(widget.onRestart),
                          onOpenViewportSwitcher: () =>
                              _runAndClose(widget.onOpenViewportSwitcher),
                          onOpenTerminal: () =>
                              _runAndClose(widget.onOpenTerminal),
                          onClearCache: () => _runAndClose(widget.onClearCache),
                          onExit: () => _runAndClose(widget.onExit),
                        ),
                        Positioned(
                          right: 0,
                          top: -6,
                          child: GestureDetector(
                            key: const Key('liquid_menu_close_btn'),
                            onTap: dismiss,
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
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
                ),
              ),
            ),

          // 3. Sidebar Seed Handle (Docked to screen edge)
          Positioned.fromRect(
            key: const Key('liquid_sidebar_seed_lens'),
            rect: seedRect,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: (_isIdle && !isMenuOpen) ? 0.60 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1017),
                  borderRadius: _isRightSide
                      ? const BorderRadius.horizontal(
                          left: Radius.circular(16),
                        )
                      : const BorderRadius.horizontal(
                          right: Radius.circular(16),
                        ),
                  border: Border.all(
                    color: statusColor,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.65),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 3.5,
                    height: 28,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.85),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Tap and drag detector on the sidebar handle
          if (!isMenuOpen)
            Positioned.fromRect(
              rect: seedRect.inflate(8),
              child: GestureDetector(
                key: const Key('liquid_sidebar_seed'),
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  openMenu();
                },
                onPanStart: (_) => _wakeUp(),
                onPanUpdate: (details) {
                  _wakeUp();
                  if (travel <= 0) return;
                  setState(() {
                    _dy = (_dy + details.delta.dy / travel).clamp(0, 1);
                    if (details.globalPosition.dx < mq.size.width * 0.4) {
                      _isRightSide = false;
                    } else if (details.globalPosition.dx >
                        mq.size.width * 0.6) {
                      _isRightSide = true;
                    }
                  });
                },
                onPanEnd: (_) {
                  _wakeUp();
                  HapticFeedback.lightImpact();
                  _savePosition();
                },
              ),
            ),

          // Position tracking key for automated tests
          Positioned.fromRect(
            key: const Key('liquid_sidebar_seed_position'),
            rect: seedRect,
            child: const IgnorePointer(),
          ),
        ],
      ),
    );
  }
}
