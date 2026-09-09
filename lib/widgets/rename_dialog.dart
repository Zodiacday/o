import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../models/session_item.dart';
import '../theme/app_theme.dart';

class RenameDialog extends StatefulWidget {
  final SessionItem item;
  final ValueChanged<String> onSaved;

  const RenameDialog({super.key, required this.item, required this.onSaved});

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.title);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final newName = _controller.text.trim();
    if (newName.isEmpty) return;
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    widget.onSaved(newName);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rename preview',
                        style: AppTypography.modalTitle(),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
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
                  'Give this connection a name you will recognize.',
                  style: AppTypography.subtitle(),
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  style: AppTypography.body(fontSize: 15),
                  cursorColor: AppTheme.cyan,
                  decoration: InputDecoration(
                    hintText: 'Project name',
                    hintStyle: AppTypography.body(
                      fontSize: 15,
                      color: AppTheme.textMuted,
                    ),
                    prefixIcon: const Icon(
                      PhosphorIconsRegular.textT,
                      size: 17,
                      color: AppTheme.textMuted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.previewBorder),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.cyan, width: 1.2),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: AppTypography.button(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Bounceable(
                      onTap: _save,
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
                          'Save',
                          style: AppTypography.button(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
