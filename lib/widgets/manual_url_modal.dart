import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_theme.dart';

class ManualUrlModal extends StatefulWidget {
  final ValueChanged<String> onConnect;

  const ManualUrlModal({super.key, required this.onConnect});

  @override
  State<ManualUrlModal> createState() => _ManualUrlModalState();
}

class _ManualUrlModalState extends State<ManualUrlModal> {
  final _textController = TextEditingController(text: 'http://');

  bool get _isValid {
    final value = _textController.text.trim();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _setPort(String port) {
    final current = _textController.text.trim();
    if (!current.contains(':') ||
        current == 'http://' ||
        current == 'https://') {
      _textController.text = '$current$port';
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
      setState(() {});
    }
  }

  Future<void> _pasteClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      HapticFeedback.lightImpact();
      _textController.text = text;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
      setState(() {});
    }
  }

  void _connect() {
    final url = _textController.text.trim();
    if (!_isValid) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    widget.onConnect(url);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        color: AppTheme.background,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 34,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open preview',
                          style: GoogleFonts.inter(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter the URL from your Flutter terminal.',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      PhosphorIconsRegular.x,
                      size: 19,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Semantics(
                textField: true,
                label: 'Preview URL',
                hint: 'Enter an HTTP or HTTPS preview URL',
                child: TextField(
                  controller: _textController,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.jetBrainsMono(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                  cursorColor: AppTheme.cyan,
                  decoration: InputDecoration(
                    hintText: 'http://192.168.0.25:8090',
                    hintStyle: GoogleFonts.jetBrainsMono(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      PhosphorIconsRegular.link,
                      color: AppTheme.textMuted,
                      size: 17,
                    ),
                    suffixIcon: _textController.text.isNotEmpty &&
                            _textController.text != 'http://' &&
                            _textController.text != 'https://'
                        ? IconButton(
                            tooltip: 'Clear input',
                            icon: const Icon(
                              PhosphorIconsRegular.xCircle,
                              color: AppTheme.textMuted,
                              size: 17,
                            ),
                            onPressed: () {
                              _textController.text = 'http://';
                              _textController.selection =
                                  TextSelection.fromPosition(
                                const TextPosition(offset: 7),
                              );
                              setState(() {});
                            },
                          )
                        : IconButton(
                            tooltip: 'Paste from clipboard',
                            icon: const Icon(
                              PhosphorIconsRegular.clipboardText,
                              color: AppTheme.cyan,
                              size: 17,
                            ),
                            onPressed: _pasteClipboard,
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.previewBorder),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.previewBorder),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.cyan, width: 1.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Common ports',
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 18,
                children: [':8090', ':8080', ':8081', ':3000', ':5000']
                    .map(
                      (port) => InkWell(
                        onTap: () => _setPort(port),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            port,
                            style: GoogleFonts.jetBrainsMono(
                              color: AppTheme.cyan,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 22),
              Semantics(
                button: true,
                enabled: _isValid,
                label: 'Open preview',
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isValid ? _connect : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.cyan,
                      disabledBackgroundColor: AppTheme.previewSurfaceElevated,
                      foregroundColor: Colors.black,
                      disabledForegroundColor: AppTheme.textMuted,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                    child: const Text('Open preview'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
