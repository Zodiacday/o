import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_theme.dart';
import 'dev_menu_content.dart';

export 'liquid_sidebar_seed.dart'
    show LiquidDevControlController, LiquidDevControlDriver;

import 'liquid_sidebar_seed.dart';

/// A deliberately isolated package-native benchmark for the UI Lab.
///
/// It lets us judge LiquidGlassMorph's own geometry and spring motion without
/// confusing those results with PreviewPort's deterministic nano contour.
class NativeGlassMorphLab extends StatefulWidget {
  final LiquidDevControlController? controller;
  final VoidCallback onHotReload;
  final VoidCallback onRestart;
  final VoidCallback onOpenViewportSwitcher;
  final VoidCallback onOpenTerminal;
  final VoidCallback onClearCache;
  final VoidCallback onExit;
  final String selectedDeviceName;
  final IconData selectedDeviceIcon;
  final int terminalLogCount;
  final bool isCliConnected;
  final String? title;

  const NativeGlassMorphLab({
    super.key,
    this.controller,
    required this.onHotReload,
    required this.onRestart,
    required this.onOpenViewportSwitcher,
    required this.onOpenTerminal,
    required this.onClearCache,
    required this.onExit,
    required this.selectedDeviceName,
    required this.selectedDeviceIcon,
    required this.terminalLogCount,
    this.isCliConnected = true,
    this.title,
  });

  @override
  State<NativeGlassMorphLab> createState() => _NativeGlassMorphLabState();
}

class _NativeGlassMorphLabState extends State<NativeGlassMorphLab>
    implements LiquidDevControlDriver {
  bool _open = false;

  @override
  bool get isOpen => _open;

  @override
  Future<void> openMenu() async => _setOpen(true);

  @override
  Future<void> dismiss() async => _setOpen(false);

  @override
  Future<void> openSatellites() async => _setOpen(true);

  @override
  Future<void> toggle() async => _toggle();

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(this);
  }

  @override
  void didUpdateWidget(covariant NativeGlassMorphLab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach(this);
      widget.controller?.attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(this);
    super.dispose();
  }

  void _setOpen(bool value) {
    if (!mounted || _open == value) return;
    setState(() => _open = value);
    HapticFeedback.mediumImpact();
  }

  void _toggle() {
    _setOpen(!_open);
  }

  void _runAndClose(VoidCallback action) {
    setState(() => _open = false);
    HapticFeedback.selectionClick();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final menuWidth = (mq.size.width - 56).clamp(260.0, 318.0);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_open)
          GestureDetector(
            key: const Key('native_glass_dismiss_layer'),
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.42)),
          ),
        Positioned(
          right: 14,
          top: (mq.size.height * 0.65 - 196).clamp(116.0, mq.size.height - 420),
          width: menuWidth,
          height: 392,
          child: Align(
            alignment: Alignment.centerRight,
            child: LiquidGlassMorph(
              key: const Key('native_glass_morph'),
              alignment: Alignment.centerRight,
              motion: LiquidGlassMorphMotion.droplet,
              smoothness: 56,
              // The package owns the surface, neck, and spring. PreviewPort
              // supplies only the collapsed control and expanded content.
              style: const LiquidGlassStyle(),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 140),
                child: _open
                    ? SizedBox(
                        key: const ValueKey('native_glass_surface'),
                        width: menuWidth,
                        height: 392,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                          child: Stack(
                            children: [
                              DevMenuContent(
                                title: widget.title,
                                isCliConnected: widget.isCliConnected,
                                terminalLogCount: widget.terminalLogCount,
                                selectedDeviceName: widget.selectedDeviceName,
                                selectedDeviceIcon: widget.selectedDeviceIcon,
                                onHotReload: () =>
                                    _runAndClose(widget.onHotReload),
                                onRestart: () => _runAndClose(widget.onRestart),
                                onOpenViewportSwitcher: () =>
                                    _runAndClose(widget.onOpenViewportSwitcher),
                                onOpenTerminal: () =>
                                    _runAndClose(widget.onOpenTerminal),
                                onClearCache: () =>
                                    _runAndClose(widget.onClearCache),
                                onExit: () => _runAndClose(widget.onExit),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  key: const Key('native_glass_close'),
                                  onPressed: _toggle,
                                  icon: const Icon(
                                    PhosphorIconsRegular.x,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox(
                        width: 52,
                        height: 52,
                        child: Icon(
                          PhosphorIconsRegular.slidersHorizontal,
                          color: AppTheme.cyan,
                          size: 21,
                        ),
                      ),
              ),
            ),
          ),
        ),
        if (!_open)
          Positioned(
            key: const Key('native_glass_seed'),
            right: 14,
            top: (mq.size.height * 0.65 - 26).clamp(286.0, mq.size.height - 78),
            width: 52,
            height: 52,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
            ),
          ),
      ],
    );
  }
}
