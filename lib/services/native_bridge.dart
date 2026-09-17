import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/network_request_entry.dart';
import 'native_bridge_script.dart';

enum NativeHapticType { selection, light, medium, heavy, vibrate }

/// Dispatches native hardware features (Taptic feedback, title synchronization)
/// triggered by the previewed Flutter Web app over a JavaScript channel.
class NativeBridgeHandler {
  final void Function(String title)? onTitleChanged;
  final void Function(NativeHapticType hapticType)? onHapticTriggered;
  final void Function(bool isDarkContent)? onThemeChanged;
  final void Function(Color color)? onThemeColorDetected;
  final void Function()? onPageReady;
  final void Function(String message, String level)? onConsoleLog;
  final void Function(NetworkRequestEntry request)? onNetworkRequest;
  final void Function(String message, String? file, int? line)? onFatalError;
  final void Function(String reason)? onBlankScreenDetected;

  const NativeBridgeHandler({
    this.onTitleChanged,
    this.onHapticTriggered,
    this.onThemeChanged,
    this.onThemeColorDetected,
    this.onPageReady,
    this.onConsoleLog,
    this.onNetworkRequest,
    this.onFatalError,
    this.onBlankScreenDetected,
  });

  /// Generates the complete Expo-compatible and PreviewPort injection script
  /// populated with the host phone's real hardware insets and device metrics.
  static String buildInjectionScript({
    double topInset = 0,
    double bottomInset = 0,
    double leftInset = 0,
    double rightInset = 0,
    double width = 0,
    double height = 0,
    double pixelRatio = 1.0,
    String platform = 'ios',
  }) {
    final top = topInset.toStringAsFixed(1);
    final bottom = bottomInset.toStringAsFixed(1);
    final left = leftInset.toStringAsFixed(1);
    final right = rightInset.toStringAsFixed(1);
    final hasDynamicIsland = platform == 'ios' && topInset >= 54;
    final hasNotch = topInset > 24;

    final insetsPreamble =
        '''
(function() {
  // Expo react-native-safe-area-context standard hardware metrics
  var insets = {
    top: $top,
    bottom: $bottom,
    left: $left,
    right: $right
  };
  window.__PREVIEWPORT_INSETS__ = insets;
  window.safeAreaInsets = insets;

  window.PreviewPort = window.PreviewPort || {};
  window.PreviewPort.safeArea = insets;
  window.PreviewPort.device = {
    platform: '$platform',
    pixelRatio: ${pixelRatio.toStringAsFixed(2)},
    screenWidth: ${width.toStringAsFixed(1)},
    screenHeight: ${height.toStringAsFixed(1)},
    isIOS: ${platform == 'ios'},
    isAndroid: ${platform == 'android'},
    hasDynamicIsland: $hasDynamicIsland,
    hasNotch: $hasNotch
  };

  try {
    var styleId = '__previewport_device_insets';
    var styleEl = document.getElementById(styleId);
    if (!styleEl) {
      styleEl = document.createElement('style');
      styleEl.id = styleId;
      if (document.head) document.head.appendChild(styleEl);
    }
    if (styleEl) {
      styleEl.textContent = ':root { --sat: ${top}px; --sab: ${bottom}px; --sal: ${left}px; --sar: ${right}px; --safe-area-inset-top: ${top}px; --safe-area-inset-bottom: ${bottom}px; --safe-area-inset-left: ${left}px; --safe-area-inset-right: ${right}px; }';
    }
  } catch (e) {}

  function applyInsets(ins) {
    if (!ins) return;
    window.__PREVIEWPORT_INSETS__ = ins;
    window.safeAreaInsets = ins;
    window.PreviewPort = window.PreviewPort || {};
    window.PreviewPort.safeArea = ins;
    try {
      var styleEl = document.getElementById('__previewport_device_insets');
      if (styleEl) {
        styleEl.textContent = ':root { --sat: ' + ins.top + 'px; --sab: ' + ins.bottom + 'px; --sal: ' + ins.left + 'px; --sar: ' + ins.right + 'px; --safe-area-inset-top: ' + ins.top + 'px; --safe-area-inset-bottom: ' + ins.bottom + 'px; --safe-area-inset-left: ' + ins.left + 'px; --safe-area-inset-right: ' + ins.right + 'px; }';
      }
      window.dispatchEvent(new CustomEvent('previewport:insets-change', { detail: ins }));
    } catch (e) {}
  }

  window.PreviewPort.updateInsets = applyInsets;
})();
''';

    return insetsPreamble + nativeBridgeCoreScript;
  }

  /// Default baseline script for static evaluation or testing.
  static String get injectionScript => buildInjectionScript();

  /// Generates script to update safe area insets dynamically without a full reload.
  static String buildUpdateInsetsScript({
    required double top,
    required double bottom,
    required double left,
    required double right,
  }) {
    final t = top.toStringAsFixed(1);
    final b = bottom.toStringAsFixed(1);
    final l = left.toStringAsFixed(1);
    final r = right.toStringAsFixed(1);
    return 'try { if (window.PreviewPort && window.PreviewPort.updateInsets) { window.PreviewPort.updateInsets({ top: $t, bottom: $b, left: $l, right: $r }); } } catch (e) {}';
  }

  /// Generates script to update network condition ('normal', '3g', 'offline').
  static String buildSetNetworkConditionScript(String condition) {
    final sanitized = condition.replaceAll('"', '');
    return 'try { if (window.PreviewPort && window.PreviewPort.setNetworkCondition) { window.PreviewPort.setNetworkCondition("$sanitized"); } } catch (e) {}';
  }

  /// Generates script to update mock geolocation coordinates or clear them.
  static String buildSetMockLocationScript({
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
  }) {
    if (latitude == null || longitude == null) {
      return 'try { if (window.PreviewPort && window.PreviewPort.setMockLocation) { window.PreviewPort.setMockLocation(null); } } catch (e) {}';
    }
    final lat = latitude.toStringAsFixed(6);
    final lng = longitude.toStringAsFixed(6);
    final alt = (altitude ?? 15.0).toStringAsFixed(1);
    final acc = (accuracy ?? 5.0).toStringAsFixed(1);
    return 'try { if (window.PreviewPort && window.PreviewPort.setMockLocation) { window.PreviewPort.setMockLocation({ latitude: $lat, longitude: $lng, altitude: $alt, accuracy: $acc }); } } catch (e) {}';
  }

  /// Processes raw incoming string payloads from the JavaScriptChannel.
  void handleMessage(String rawJson) {
    if (rawJson.trim().isEmpty) return;
    try {
      final data = jsonDecode(rawJson);
      if (data is! Map) return;

      final type = data['type'];
      if (type == 'haptic') {
        final subtype = data['subtype'] as String?;
        final hapticType = _parseHapticType(subtype);
        _triggerHaptic(hapticType);
        onHapticTriggered?.call(hapticType);
      } else if (type == 'title') {
        final title = data['value'] as String?;
        if (title != null && title.trim().isNotEmpty) {
          onTitleChanged?.call(title.trim());
        }
      } else if (type == 'theme') {
        final isDark = data['isDark'];
        if (isDark is bool) {
          onThemeChanged?.call(isDark);
        }
        final colorStr = data['color'] as String?;
        if (colorStr != null && colorStr.isNotEmpty) {
          final parsed = parseCssColor(colorStr);
          if (parsed != null && parsed.a > 0) {
            onThemeColorDetected?.call(parsed);
          }
        }
      } else if (type == 'ready') {
        onPageReady?.call();
      } else if (type == 'console') {
        final message = data['message'] as String?;
        final level = data['level'] as String? ?? 'info';
        if (message != null && message.trim().isNotEmpty) {
          onConsoleLog?.call(message.trim(), level);
        }
      } else if (type == 'network') {
        final reqMap = data['request'];
        if (reqMap is Map<String, dynamic>) {
          final entry = NetworkRequestEntry.fromJson(reqMap);
          onNetworkRequest?.call(entry);
        }
      } else if (type == 'fatal_startup_error') {
        final message = data['message'] as String? ?? 'Fatal startup error';
        final file = data['file'] as String?;
        final line = data['line'] as int?;
        onFatalError?.call(message, file, line);
      } else if (type == 'blank_screen_detected') {
        final reason = data['reason'] as String? ?? 'Blank screen detected';
        onBlankScreenDetected?.call(reason);
      }
    } catch (_) {
      // Ignore malformed payloads from untrusted web pages
    }
  }

  static NativeHapticType _parseHapticType(String? subtype) {
    switch (subtype?.toLowerCase()) {
      case 'selection':
        return NativeHapticType.selection;
      case 'medium':
        return NativeHapticType.medium;
      case 'heavy':
        return NativeHapticType.heavy;
      case 'vibrate':
        return NativeHapticType.vibrate;
      case 'light':
      default:
        return NativeHapticType.light;
    }
  }

  static void _triggerHaptic(NativeHapticType type) {
    switch (type) {
      case NativeHapticType.selection:
        HapticFeedback.selectionClick();
        break;
      case NativeHapticType.light:
        HapticFeedback.lightImpact();
        break;
      case NativeHapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case NativeHapticType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case NativeHapticType.vibrate:
        HapticFeedback.vibrate();
        break;
    }
  }

  /// Parses standard CSS color definitions (hex, rgb, rgba, white, black) into a Flutter [Color].
  static Color? parseCssColor(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final s = raw.trim().toLowerCase();
    if (s == 'transparent' || s == 'inherit' || s == 'initial') return null;
    if (s == 'white') return const Color(0xFFFFFFFF);
    if (s == 'black') return const Color(0xFF000000);

    if (s.startsWith('#')) {
      final hex = s.substring(1);
      if (hex.length == 3) {
        final r = hex[0];
        final g = hex[1];
        final b = hex[2];
        final val = int.tryParse('FF$r$r$g$g$b$b', radix: 16);
        if (val != null) return Color(val);
      } else if (hex.length == 6) {
        final val = int.tryParse('FF$hex', radix: 16);
        if (val != null) return Color(val);
      } else if (hex.length == 8) {
        final r = hex.substring(0, 2);
        final g = hex.substring(2, 4);
        final b = hex.substring(4, 6);
        final a = hex.substring(6, 8);
        final val = int.tryParse('$a$r$g$b', radix: 16);
        if (val != null) return Color(val);
      }
    }

    final rgbRegex = RegExp(
      r'rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*([\d.]+))?\s*\)',
    );
    final match = rgbRegex.firstMatch(s);
    if (match != null) {
      final r = int.tryParse(match.group(1)!) ?? 0;
      final g = int.tryParse(match.group(2)!) ?? 0;
      final b = int.tryParse(match.group(3)!) ?? 0;
      final aStr = match.group(4);
      final double a = aStr != null ? (double.tryParse(aStr) ?? 1.0) : 1.0;
      final alpha = (a * 255).round().clamp(0, 255);
      return Color.fromARGB(alpha, r, g, b);
    }

    return null;
  }
}
