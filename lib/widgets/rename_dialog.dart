import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      title: Text(
        'Rename Project',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Project nickname',
          hintStyle: const TextStyle(color: AppTheme.textMuted),
          filled: true,
          fillColor: AppTheme.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.lightBlue,
            foregroundColor: AppTheme.deepNavy,
            elevation: 0,
          ),
          child: const Text('Save'),
          onPressed: () {
            final newName = _controller.text.trim();
            if (newName.isNotEmpty) {
              Navigator.of(context).pop();
              widget.onSaved(newName);
            }
          },
        ),
      ],
    );
  }
}
