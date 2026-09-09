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
      textTheme: GoogleFonts.titilliumWebTextTheme(ThemeData.dark().textTheme),
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

/// Purpose-driven Cyber Telemetry / HUD typography system for PreviewPort.
///
/// Built on:
/// - [Rajdhani]: Aeronautic display & condensed headers.
/// - [Titillium Web]: High-legibility digital interface sans.
/// - [Share Tech Mono]: Clinical data, CLI syntax, and tabular monospace readouts.
class AppTypography {
  const AppTypography._();

  // ---------------------------------------------------------------------------
  // 1. Telemetry Display & Headers (Rajdhani)
  // ---------------------------------------------------------------------------

  /// Primary screen mastheads (e.g., "Scan history", "Settings").
  static TextStyle displayHero({Color color = AppTheme.textPrimary}) =>
      GoogleFonts.rajdhani(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.6,
        height: 1.1,
      );

  /// Major functional titles (e.g., "Connect to a Flutter preview").
  static TextStyle headline({Color color = AppTheme.textPrimary}) =>
      GoogleFonts.rajdhani(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.4,
        height: 1.15,
      );

  /// Card headers & modal dialog titles.
  static TextStyle cardTitle({Color color = Colors.white}) =>
      GoogleFonts.rajdhani(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.25,
      );

  /// Popups and action sheet headers.
  static TextStyle modalTitle({Color color = AppTheme.textPrimary}) =>
      GoogleFonts.rajdhani(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
      );

  /// All-caps military/aerospace section telemetry badges.
  /// (e.g., "RECENT PREVIEWS", "CONNECTION", "STORAGE").
  static TextStyle sectionHud({Color color = AppTheme.textSecondary}) =>
      GoogleFonts.rajdhani(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.4,
      );

  /// Action chip and slidable label typography (e.g., "Share", "Rename").
  static TextStyle actionLabel({Color color = Colors.white}) =>
      GoogleFonts.rajdhani(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.6,
      );

  // ---------------------------------------------------------------------------
  // 2. Interface Body & Interactive Controls (Titillium Web)
  // ---------------------------------------------------------------------------

  /// Standard body copy and dialog explanations.
  static TextStyle body({
    Color color = AppTheme.textPrimary,
    double fontSize = 14.5,
    double? height = 1.35,
  }) =>
      GoogleFonts.titilliumWeb(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color,
        letterSpacing: 0.1,
        height: height,
      );

  /// Semi-bold emphasis in body contexts or setting row labels.
  static TextStyle bodyMedium({
    Color color = AppTheme.textPrimary,
    double fontSize = 14.5,
  }) =>
      GoogleFonts.titilliumWeb(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.0,
      );

  /// Project names and list row headings.
  static TextStyle itemTitle({
    Color color = Colors.white,
    double fontSize = 15,
  }) =>
      GoogleFonts.titilliumWeb(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.1,
      );

  /// Supporting labels, secondary captions, and hints.
  static TextStyle subtitle({
    Color color = AppTheme.textSecondary,
    double fontSize = 12.5,
    double? height = 1.35,
  }) =>
      GoogleFonts.titilliumWeb(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color,
        height: height,
      );

  /// Tactile button and interactive pill labels.
  static TextStyle button({
    Color color = Colors.black,
    double fontSize = 13,
  }) =>
      GoogleFonts.titilliumWeb(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.3,
      );

  /// Floating glass navbar item labels.
  static TextStyle navLabel({required bool isSelected}) =>
      GoogleFonts.titilliumWeb(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        letterSpacing: isSelected ? 0.6 : 0.4,
      );

  // ---------------------------------------------------------------------------
  // 3. Machine Data, Code & Tabular Telemetry (Share Tech Mono)
  // ---------------------------------------------------------------------------

  /// Raw URLs, endpoints, ports, and relative timestamps.
  static TextStyle monoData({
    Color color = AppTheme.textSecondary,
    double fontSize = 11,
  }) =>
      GoogleFonts.shareTechMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color,
        letterSpacing: 0.3,
      );

  /// CLI syntax and executable tokens (e.g., `pp start`).
  static TextStyle monoCommand({
    Color color = AppTheme.cyan,
    double fontSize = 12,
  }) =>
      GoogleFonts.shareTechMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.4,
      );

  /// Numerical stats, memory metrics, and session counters.
  static TextStyle monoCounter({Color color = AppTheme.textMuted}) =>
      GoogleFonts.shareTechMono(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.5,
      );
}
