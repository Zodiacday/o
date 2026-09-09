import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toastification/toastification.dart';
import '../theme/app_theme.dart';

/// Centralized glass HUD notification toast system for PreviewPort.
///
/// Standardizes all feedback messages with dark frosted glass styling,
/// specular neon rims, tailored typography, and automatic tactile haptics.
class AppToast {
  const AppToast._();

  static void success(
    BuildContext context, {
    required String title,
    String? description,
    Duration autoCloseDuration = const Duration(seconds: 2),
  }) {
    HapticFeedback.lightImpact();
    _show(
      context: context,
      type: ToastificationType.success,
      primaryColor: AppTheme.cyan,
      title: title,
      description: description,
      autoCloseDuration: autoCloseDuration,
    );
  }

  static void warning(
    BuildContext context, {
    required String title,
    String? description,
    Duration autoCloseDuration = const Duration(seconds: 3),
  }) {
    HapticFeedback.mediumImpact();
    _show(
      context: context,
      type: ToastificationType.warning,
      primaryColor: const Color(0xFFF59E0B),
      title: title,
      description: description,
      autoCloseDuration: autoCloseDuration,
    );
  }

  static void info(
    BuildContext context, {
    required String title,
    String? description,
    Duration autoCloseDuration = const Duration(seconds: 2),
  }) {
    HapticFeedback.selectionClick();
    _show(
      context: context,
      type: ToastificationType.info,
      primaryColor: AppTheme.cyan,
      title: title,
      description: description,
      autoCloseDuration: autoCloseDuration,
    );
  }

  static void error(
    BuildContext context, {
    required String title,
    String? description,
    Duration autoCloseDuration = const Duration(seconds: 3),
  }) {
    HapticFeedback.heavyImpact();
    _show(
      context: context,
      type: ToastificationType.error,
      primaryColor: const Color(0xFFEF4444),
      title: title,
      description: description,
      autoCloseDuration: autoCloseDuration,
    );
  }

  static void _show({
    required BuildContext context,
    required ToastificationType type,
    required Color primaryColor,
    required String title,
    String? description,
    required Duration autoCloseDuration,
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flat,
      alignment: Alignment.topCenter,
      autoCloseDuration: autoCloseDuration,
      primaryColor: primaryColor,
      backgroundColor: const Color(0xF5101216),
      foregroundColor: Colors.white,
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: primaryColor.withValues(alpha: 0.38),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.12),
          blurRadius: 18,
          offset: const Offset(0, 4),
        ),
      ],
      title: Text(
        title,
        style: GoogleFonts.rajdhani(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.2,
        ),
      ),
      description: description != null && description.isNotEmpty
          ? Text(
              description,
              style: GoogleFonts.titilliumWeb(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF94A3B8),
                height: 1.3,
              ),
            )
          : null,
      showProgressBar: false,
      closeButtonShowType: CloseButtonShowType.none,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
