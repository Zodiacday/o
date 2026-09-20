import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

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
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.previewBorder),
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
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.35,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    LucideIcons.x,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Give this connection a name you will recognize.',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 15,
              ),
              cursorColor: AppTheme.cyan,
              decoration: InputDecoration(
                hintText: 'Project name',
                hintStyle: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 15,
                ),
                prefixIcon: const Icon(
                  LucideIcons.type,
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.cyan,
                    foregroundColor: Colors.black,
                    elevation: 0,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
