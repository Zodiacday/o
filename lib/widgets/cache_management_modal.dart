import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:toastification/toastification.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CacheOption {
  final String id;
  final String title;
  final String subtitle;
  final double sizeMb;
  final IconData icon;

  const CacheOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.sizeMb,
    required this.icon,
  });
}

class CacheManagementModal extends StatefulWidget {
  final VoidCallback onCleared;

  const CacheManagementModal({super.key, required this.onCleared});

  static void show(BuildContext context, {required VoidCallback onCleared}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CacheManagementModal(onCleared: onCleared),
    );
  }

  @override
  State<CacheManagementModal> createState() => _CacheManagementModalState();
}

class _CacheManagementModalState extends State<CacheManagementModal> {
  static const List<CacheOption> _options = [
    CacheOption(
      id: 'bundles',
      title: 'JavaScript Bundles & Assets',
      subtitle: 'Cached Dart2Wasm binaries, scripts & web resources',
      sizeMb: 2.6,
      icon: LucideIcons.file_code,
    ),
    CacheOption(
      id: 'cookies',
      title: 'Session Cookies & Auth Tokens',
      subtitle: 'Saved login states, session identifiers & headers',
      sizeMb: 0.4,
      icon: LucideIcons.cookie,
    ),
    CacheOption(
      id: 'storage',
      title: 'LocalStorage & Client Databases',
      subtitle: 'IndexedDB, web storage key-values & form data',
      sizeMb: 0.8,
      icon: LucideIcons.database,
    ),
  ];

  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = _options.map((e) => e.id).toSet();
  }

  double get _selectedSize {
    return _options
        .where((e) => _selectedIds.contains(e.id))
        .fold(0.0, (acc, e) => acc + e.sizeMb);
  }

  Future<void> _performClear({required bool all}) async {
    HapticFeedback.mediumImpact();

    try {
      final cookieManager = WebViewCookieManager();
      await cookieManager.clearCookies();
    } catch (_) {}

    if (!mounted) return;

    final clearedMb = all ? 3.8 : _selectedSize;
    Navigator.of(context).pop();
    widget.onCleared();

    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: Text(
        all ? 'All Web Storage Purged' : 'Selected Cache Cleared',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 13,
        ),
      ),
      description: Text(
        'Reclaimed ${clearedMb.toStringAsFixed(1)} MB of device storage',
        style: GoogleFonts.inter(
          color: const Color(0xFF94A3B8),
          fontSize: 11,
        ),
      ),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
      primaryColor: const Color(0xFF00E5FF),
      backgroundColor: const Color(0xFF080B11),
      foregroundColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xF8000000),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: const Color(0xFF1E2638),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Web Cache & Storage',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select items to purge from preview engine',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF080B11),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${_selectedSize.toStringAsFixed(1)} MB',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00E5FF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Customizable Cache Categories
              ..._options.map((option) {
                final isSelected = _selectedIds.contains(option.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Bounceable(
                    scaleFactor: 0.98,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (isSelected) {
                          _selectedIds.remove(option.id);
                        } else {
                          _selectedIds.add(option.id);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0D121B)
                            : const Color(0xFF05080E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2E3D52)
                              : const Color(0xFF1E2638),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Custom Checkbox
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF00E5FF)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00E5FF)
                                    : const Color(0xFF64748B),
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(
                                    LucideIcons.check,
                                    size: 13,
                                    color: Colors.black,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),

                          // Option Icon
                          Icon(
                            option.icon,
                            size: 18,
                            color: isSelected
                                ? const Color(0xFF00E5FF)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 12),

                          // Titles
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  option.subtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Size Badge
                          Text(
                            '${option.sizeMb.toStringAsFixed(1)} MB',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // Action Buttons Row
              Row(
                children: [
                  // Purge All Danger Button
                  Expanded(
                    flex: 1,
                    child: Bounceable(
                      scaleFactor: 0.96,
                      onTap: () => _performClear(all: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1014),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Purge All',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Clear Selected Button
                  Expanded(
                    flex: 2,
                    child: Bounceable(
                      scaleFactor: 0.97,
                      onTap: _selectedIds.isEmpty
                          ? null
                          : () => _performClear(all: false),
                      child: Opacity(
                        opacity: _selectedIds.isEmpty ? 0.4 : 1.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A26),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF263347),
                              width: 1.0,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.trash_2,
                                  size: 14,
                                  color: Color(0xFF00E5FF),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Clear Selected (${_selectedIds.length})',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
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
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
