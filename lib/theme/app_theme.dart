import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Pitch Black OLED Palette
  static const Color background = Color(0xFF000000); // Pure Pitch Black OLED
  static const Color surface = Color(0xFF000000); // Pure Pitch Black Surface
  static const Color glassSurface = Color(0xF2000000);
  static const Color surfaceHover = Color(0xFF0A0A0A);
  static const Color card = Color(0xFF000000);

  // Homepage-only surfaces. Existing navigation and screens keep their
  // current colors; these tokens are used by the scan-first landing surface.
  static const Color previewSurface = Color(0xFF080808);
  static const Color previewSurfaceElevated = Color(0xFF111111);
  static const Color previewBorder = Color(0xFF242424);

  // Ethereal Electric Cyan / Sky Blue
  static const Color lightBlue = Color(0xFF38BDF8); // Electric Cyan Sky Blue
  static const Color primary = Color(0xFF38BDF8);
  static const Color cyan = Color(0xFF00E5FF); // Vibrant Cyan Glow
  static const Color deepNavy = Color(0xFF000000); // Pure Pitch Black

  // Precision Milled Slate Hairline Borders
  static const Color border = Color(0xFF1E2638); // Precision Milled Dark Slate
  static const Color borderSubtle = Color(0xFF141A26);
  static const Color borderGlow = Color(0xFF263347);

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC); // Crisp White
  static const Color textSecondary = Color(0xFF94A3B8); // Cool Steel Blue
  static const Color textMuted = Color(0xFF64748B); // Muted Slate

  // Accents
  static const Color accent = Color(0xFF00E5FF);
  static const Color statusGreen = Color(0xFF22C55E); // Connected status dot
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: background,
      dialogTheme: const DialogThemeData(backgroundColor: background),
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: cyan,
        surface: surface,
        error: danger,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
      ),
      dividerTheme: const DividerThemeData(color: borderSubtle, thickness: 1),
      useMaterial3: true,
    );
  }
}
