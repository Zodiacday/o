import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:toastification/toastification.dart';
import '../models/session_item.dart';
import '../services/history_service.dart';

class HistoryManagementModal extends StatefulWidget {
  final VoidCallback onUpdated;

  const HistoryManagementModal({super.key, required this.onUpdated});

  static void show(BuildContext context, {required VoidCallback onUpdated}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => HistoryManagementModal(onUpdated: onUpdated),
    );
  }

  @override
  State<HistoryManagementModal> createState() => _HistoryManagementModalState();
}

class _HistoryManagementModalState extends State<HistoryManagementModal> {
  List<SessionItem> _items = [];
  bool _isLoading = true;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final list = await HistoryService.getHistory();
    if (mounted) {
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSingle(SessionItem item) async {
    HapticFeedback.lightImpact();
    await HistoryService.removeSession(item.id);
    _selectedIds.remove(item.id);
    await _loadItems();
    widget.onUpdated();

    if (!mounted) return;
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      title: Text(
        'Session Removed',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 13,
        ),
      ),
      description: Text(
        item.title,
        style: GoogleFonts.inter(
          color: const Color(0xFF94A3B8),
          fontSize: 11,
        ),
      ),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 2),
      primaryColor: const Color(0xFF00E5FF),
      backgroundColor: const Color(0xFF080B11),
      foregroundColor: Colors.white,
    );
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.mediumImpact();

    final count = _selectedIds.length;
    for (final id in _selectedIds.toList()) {
      await HistoryService.removeSession(id);
    }
    _selectedIds.clear();
    await _loadItems();
    widget.onUpdated();

    if (!mounted) return;
    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      title: Text(
        '$count Sessions Deleted',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 13,
        ),
      ),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 2),
      primaryColor: const Color(0xFF00E5FF),
      backgroundColor: const Color(0xFF080B11),
      foregroundColor: Colors.white,
    );
  }

  Future<void> _clearAll() async {
    HapticFeedback.mediumImpact();
    await HistoryService.clearAll();
    _selectedIds.clear();
    await _loadItems();
    widget.onUpdated();

    if (!mounted) return;
    Navigator.of(context).pop();

    toastification.show(
      context: context,
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      title: Text(
        'All Session History Cleared',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 13,
        ),
      ),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 2),
      primaryColor: const Color(0xFFEF4444),
      backgroundColor: const Color(0xFF080B11),
      foregroundColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: media.size.height * 0.75,
          ),
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
                        'Session History Manager',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Customize individual sessions or clear all',
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
                        color: const Color(0xFF1E2638),
                      ),
                    ),
                    child: Text(
                      '${_items.length} Scans',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Items List or Empty State
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(
                      color: Color(0xFF00E5FF),
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (_items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF080B11),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1E2638),
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.check,
                            color: Color(0xFF22C55E),
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Sessions in History',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'History is already completely clean',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final isSelected = _selectedIds.contains(item.id);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
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
                            // Selection Checkbox
                            Bounceable(
                              scaleFactor: 0.9,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (isSelected) {
                                    _selectedIds.remove(item.id);
                                  } else {
                                    _selectedIds.add(item.id);
                                  }
                                });
                              },
                              child: Container(
                                width: 22,
                                height: 22,
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
                                        size: 14,
                                        color: Colors.black,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Logo
                            Container(
                              width: 32,
                              height: 32,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF000000),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF1E2638),
                                ),
                              ),
                              child: Image.asset(
                                'assets/previewport-logo-transparent.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Title & URL
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.url,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10.5,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Individual Delete Button
                            Bounceable(
                              scaleFactor: 0.9,
                              onTap: () => _deleteSingle(item),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A0F12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.trash_2,
                                  size: 14,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              // Action Buttons Row
              if (_items.isNotEmpty)
                Row(
                  children: [
                    // Clear All Button
                    Expanded(
                      flex: 1,
                      child: Bounceable(
                        scaleFactor: 0.96,
                        onTap: _clearAll,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1014),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Clear All',
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

                    // Delete Selected Button
                    Expanded(
                      flex: 2,
                      child: Bounceable(
                        scaleFactor: 0.97,
                        onTap: _selectedIds.isEmpty ? null : _deleteSelected,
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
                                    LucideIcons.trash,
                                    size: 14,
                                    color: Color(0xFF00E5FF),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete Selected (${_selectedIds.length})',
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
