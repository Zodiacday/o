import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../theme/app_theme.dart';
import '../widgets/liquid_sidebar_seed.dart';

/// Interactive UI Lab testing ground with rich backdrop for real glass refraction.
class UiLabScreen extends StatefulWidget {
  const UiLabScreen({super.key});

  @override
  State<UiLabScreen> createState() => _UiLabScreenState();
}

class _UiLabScreenState extends State<UiLabScreen> {
  bool _isCliConnected = true;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      body: LiquidGlassView(
        backgroundWidget: const _GlassTestBackdrop(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _GlassTestBackdrop(),
            Positioned(
              top: topPadding + 14,
              left: 20,
              right: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    key: const Key('ui_lab_cli_toggle'),
                    onTap: () => setState(() => _isCliConnected = !_isCliConnected),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: (_isCliConnected ? AppTheme.cyan : AppTheme.warning)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (_isCliConnected ? AppTheme.cyan : AppTheme.warning)
                              .withValues(alpha: 0.45),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isCliConnected ? AppTheme.cyan : AppTheme.warning,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isCliConnected ? AppTheme.cyan : AppTheme.warning)
                                      .withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isCliConnected ? 'CLI LIVE' : 'CLI OFFLINE',
                            style: AppTypography.monoData(
                              fontSize: 9.0,
                              color: _isCliConnected ? AppTheme.cyan : AppTheme.warning,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            LiquidSidebarSeed(
              isCliConnected: _isCliConnected,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassTestBackdrop extends StatelessWidget {
  const _GlassTestBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF090D16), Color(0xFF0E1524), Color(0xFF070A10)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header bar
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Icon(Icons.dashboard_rounded, color: AppTheme.cyan, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PreviewPort Core',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Vite Live Server 192.168.1.100:5173',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Hero gradient card (shows vibrant refraction behind glass)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFF06B6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'HOT MODULE RELOAD',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 18),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sub-50ms Sync',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Zero bundle latency streaming directly from local workstation.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Metrics row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MEMORY', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          const Text('42.8 MB', style: TextStyle(color: AppTheme.cyan, fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FRAME TIME', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          const Text('16.6 ms', style: TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Code Preview Block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D111A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Text('vite.config.ts', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontFamily: 'monospace')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'export default defineConfig({\n  server: { host: "0.0.0.0", port: 5173 },\n  plugins: [react(), tailwindcss()],\n});',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11, fontFamily: 'monospace', height: 1.5),
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
}
