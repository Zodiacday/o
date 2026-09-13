import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/floating_ghost_capsule.dart';
import '../widgets/liquid_dev_menu.dart';
import '../widgets/mini_terminal_drawer.dart';
import '../widgets/viewport_switcher_sheet.dart';

/// Interactive UI Lab & Component Sandbox.
/// Allows rapid visual iteration of PreviewPort components (starting with the Liquid Dev Menu)
/// with real-time haptics, physics, and zero dependency on live servers or WebViews.
class UiLabScreen extends StatefulWidget {
  const UiLabScreen({super.key});

  @override
  State<UiLabScreen> createState() => _UiLabScreenState();
}

class _UiLabScreenState extends State<UiLabScreen> {
  // Scenario state
  int _selectedScenarioIndex = 0;
  static const List<String> _scenarios = [
    'Liquid Dev Menu',
    'Chassis Switcher',
    'Terminal Drawer',
  ];

  // Floating Ghost Capsule & Menu state
  bool _isMenuOpen = false;
  double _capsuleDy = 0.55;
  double? _capsulePixelY;
  bool _capsuleIsRightSide = true;
  SimulatedDeviceProfile _selectedDevice = defaultDeviceProfiles.first;

  // Mock terminal logs
  final List<TerminalLogEntry> _mockLogs = [
    TerminalLogEntry(
      id: 'log-1',
      message: 'UI Lab sandbox initialized in mock mode (120 FPS)',
      level: 'info',
      source: 'flutter',
    ),
    TerminalLogEntry(
      id: 'log-2',
      message: 'LiquidDevMenuOverlay mounted with analytical metaball tether',
      level: 'info',
      source: 'web',
    ),
    TerminalLogEntry(
      id: 'log-3',
      message: 'AmbientLiquidBlobsLayer active (3 spectral nodes)',
      level: 'info',
      source: 'flutter',
    ),
  ];

  void _openViewportSwitcher() {
    setState(() => _isMenuOpen = false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ViewportSwitcherSheet(
        selected: _selectedDevice,
        nativeDevice: defaultDeviceProfiles.first,
        onSelect: (device) {
          Navigator.of(ctx).pop();
          setState(() => _selectedDevice = device);
          AppToast.success(context, title: 'Viewport: ${device.name}');
        },
      ),
    );
  }

  void _openTerminal() {
    setState(() => _isMenuOpen = false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MiniTerminalDrawer(
        logs: _mockLogs,
        onClear: () {
          setState(() => _mockLogs.clear());
          AppToast.info(context, title: 'Terminal logs cleared');
        },
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final anchorY = _capsulePixelY ??
        FloatingGhostCapsule.calculateCenterY(
          screenH: screenH,
          topInset: mq.padding.top,
          bottomInset: mq.padding.bottom,
          dy: _capsuleDy,
        );

    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: Stack(
        children: [
          // 1. Mock App Background Canvas (Simulating a real dashboard behind the HUD)
          _buildMockAppCanvas(context),

          // 2. Scenario Switcher Header Bar
          _buildScenarioHeader(mq),

          // 3. Floating Ghost Capsule HUD
          FloatingGhostCapsule(
            onHotReload: () {
              HapticFeedback.lightImpact();
              AppToast.success(context, title: '⚡ Mock Hot Reload dispatched (42ms)');
            },
            onOpenMenu: () {
              HapticFeedback.mediumImpact();
              setState(() => _isMenuOpen = true);
            },
            onOpenTerminal: _openTerminal,
            onAnnotateBug: () {
              HapticFeedback.lightImpact();
              AppToast.warning(context, title: 'Bug annotator preview');
            },
            onPositionChanged: (dy, isRight, pixelY) {
              setState(() {
                _capsuleDy = dy;
                _capsuleIsRightSide = isRight;
                _capsulePixelY = pixelY;
              });
            },
            isCliConnected: true,
          ),

          // 4. Liquid Dev Menu Overlay Rig
          LiquidDevMenuOverlay(
            isOpen: _isMenuOpen,
            onClose: () {
              HapticFeedback.selectionClick();
              setState(() => _isMenuOpen = false);
            },
            anchorY: anchorY,
            isRightSide: _capsuleIsRightSide,
            title: 'PreviewPort UI Sandbox',
            isCliConnected: true,
            selectedDeviceName: _selectedDevice.name,
            selectedDeviceIcon: _selectedDevice.icon,
            onHotReload: () {
              HapticFeedback.mediumImpact();
              AppToast.success(context, title: '⚡ Hot Reload preview (0.18s)');
            },
            onRestart: () {
              HapticFeedback.heavyImpact();
              AppToast.info(context, title: '↻ Hot Restart preview (0.45s)');
            },
            onOpenViewportSwitcher: _openViewportSwitcher,
            onOpenTerminal: _openTerminal,
            terminalLogCount: _mockLogs.length,
            onClearCache: () {
              HapticFeedback.mediumImpact();
              setState(() => _isMenuOpen = false);
              AppToast.success(context, title: 'Mock cache flushed & reset');
            },
            onExit: () {
              HapticFeedback.heavyImpact();
              setState(() => _isMenuOpen = false);
              AppToast.warning(context, title: 'Simulated Exit action confirmed');
            },
          ),

          // 5. Interactive sandbox guidance chip at the bottom
          Positioned(
            bottom: 84,
            left: 20,
            right: 20,
            child: IgnorePointer(
              ignoring: _isMenuOpen,
              child: AnimatedOpacity(
                opacity: _isMenuOpen ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x990D111A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.cyan.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.40),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          PhosphorIconsRegular.handPointing,
                          size: 14,
                          color: AppTheme.cyan,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Drag capsule along edge • Tap to bloom liquid menu',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioHeader(MediaQueryData mq) {
    return Positioned(
      top: mq.padding.top + 8,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.cyan.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.cyan.withValues(alpha: 0.45),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        PhosphorIconsRegular.flask,
                        size: 15,
                        color: AppTheme.cyan,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UI LAB & SANDBOX',
                        style: GoogleFonts.rajdhani(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Instant Local UI Iteration',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0x2200F2FE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.cyan.withValues(alpha: 0.50),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppTheme.cyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '120 FPS RIG',
                      style: AppTypography.monoData(
                        color: AppTheme.cyan,
                        fontSize: 9,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Scenario Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_scenarios.length, (index) {
                final isSelected = _selectedScenarioIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedScenarioIndex = index;
                        if (index == 1) _openViewportSwitcher();
                        if (index == 2) _openTerminal();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.cyan.withValues(alpha: 0.18)
                            : const Color(0x33101522),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.cyan
                              : Colors.white.withValues(alpha: 0.12),
                          width: isSelected ? 1.0 : 0.7,
                        ),
                      ),
                      child: Text(
                        _scenarios[index],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? AppTheme.cyan : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// Stylized Mock Application Canvas to visualize the floating capsule in context
  Widget _buildMockAppCanvas(BuildContext context) {
    return Positioned.fill(
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 110, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mock Hero Metric Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x331A2338),
                      Color(0x22101524),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MOCK APP CONTEXT',
                          style: AppTypography.sectionHud(
                            color: AppTheme.cyan,
                          ).copyWith(fontSize: 10),
                        ),
                        const Icon(
                          PhosphorIconsRegular.chartLineUp,
                          size: 16,
                          color: AppTheme.cyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$42,850.00',
                      style: GoogleFonts.rajdhani(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preview how the floating bezel dial overlays complex scrolling layouts.',
                      style: AppTypography.body(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mock Grid Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMockMiniCard(
                      icon: PhosphorIconsRegular.cpu,
                      title: 'GPU Frame Rate',
                      value: '120.0 FPS',
                      accent: AppTheme.cyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMockMiniCard(
                      icon: PhosphorIconsRegular.activity,
                      title: 'Impeller Pipeline',
                      value: 'Nominal',
                      accent: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mock Feed Items
              Text(
                'SIMULATED VIEWPORT LAYOUT',
                style: AppTypography.sectionHud(
                  color: AppTheme.textSecondary,
                ).copyWith(fontSize: 10.5),
              ),
              const SizedBox(height: 10),
              for (var i = 1; i <= 5; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0x22131926),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Icon(
                            i.isEven
                                ? PhosphorIconsRegular.deviceMobile
                                : PhosphorIconsRegular.code,
                            size: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sample Component Block #$i',
                              style: AppTypography.itemTitle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Interactive surface scroll test target',
                              style: AppTypography.subtitle(
                                fontSize: 11,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        PhosphorIconsRegular.caretRight,
                        size: 14,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockMiniCard({
    required IconData icon,
    required String title,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x22131926),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTypography.subtitle(
              fontSize: 10,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.rajdhani(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
