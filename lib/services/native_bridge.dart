import 'dart:convert';
import 'package:flutter/services.dart';

import 'native_bridge_script.dart';

enum NativeHapticType { selection, light, medium, heavy, vibrate }

/// Dispatches native hardware features (Taptic feedback, title synchronization)
/// triggered by the previewed Flutter Web app over a JavaScript channel.
class NativeBridgeHandler {
  final void Function(String title)? onTitleChanged;
  final void Function(NativeHapticType hapticType)? onHapticTriggered;
  final void Function(bool isDarkContent)? onThemeChanged;
  final void Function(String message, String level)? onConsoleLog;

  const NativeBridgeHandler({
    this.onTitleChanged,
    this.onHapticTriggered,
    this.onThemeChanged,
    this.onConsoleLog,
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
      window.dispatchEvent(new Event('resize'));
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
      } else if (type == 'console') {
        final message = data['message'] as String?;
        final level = data['level'] as String? ?? 'info';
        if (message != null && message.trim().isNotEmpty) {
          onConsoleLog?.call(message.trim(), level);
        }
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
}
