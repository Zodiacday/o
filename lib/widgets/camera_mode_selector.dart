import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum CameraMode { scan, photo }

class CameraModeSelector extends StatelessWidget {
  final CameraMode value;
  final ValueChanged<CameraMode> onChanged;

  const CameraModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Camera mode',
      child: Container(
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeButton(
              label: 'Scan',
              selected: value == CameraMode.scan,
              onPressed: () => onChanged(CameraMode.scan),
            ),
            _ModeButton(
              label: 'Photo',
              selected: value == CameraMode.photo,
              onPressed: () => onChanged(CameraMode.photo),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label mode',
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppTheme.cyan : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
