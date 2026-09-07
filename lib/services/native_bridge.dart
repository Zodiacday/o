import 'dart:convert';
import 'package:flutter/services.dart';

enum NativeHapticType {
  selection,
  light,
  medium,
  heavy,
  vibrate,
}

/// Dispatches native hardware features (Taptic feedback, title synchronization)
/// triggered by the previewed Flutter Web app over a JavaScript channel.
class NativeBridgeHandler {
  final void Function(String title)? onTitleChanged;
  final void Function(NativeHapticType hapticType)? onHapticTriggered;
  final void Function(bool isDarkContent)? onThemeChanged;

  const NativeBridgeHandler({
    this.onTitleChanged,
    this.onHapticTriggered,
    this.onThemeChanged,
  });

  /// The JavaScript snippet injected into the WebView to bridge Flutter Web
  /// calls to the native host container.
  static const String injectionScript = r'''
(function() {
  if (window.__previewPortBridgeInjected) return;
  window.__previewPortBridgeInjected = true;

  // 1. Ensure viewport-fit=cover so WebKit activates safe-area-inset-* for Dynamic Island & notch
  try {
    var metaViewport = document.querySelector('meta[name="viewport"]');
    if (!metaViewport) {
      metaViewport = document.createElement('meta');
      metaViewport.name = 'viewport';
      metaViewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
      document.head.appendChild(metaViewport);
    } else if (!metaViewport.content.includes('viewport-fit=cover')) {
      metaViewport.content += ', viewport-fit=cover';
    }
  } catch (e) {}

  // 2. Native momentum scrolling styles & eliminate web bounce
  try {
    if (!document.getElementById('__previewport_native_styles')) {
      var style = document.createElement('style');
      style.id = '__previewport_native_styles';
      style.textContent = 'html, body { overscroll-behavior-y: none; -webkit-tap-highlight-color: transparent; }';
      document.head.appendChild(style);
    }
  } catch (e) {}

  // 3. Monkey-patch navigator.vibrate so Flutter Web's HapticFeedback triggers native Taptic Engine
  var originalVibrate = window.navigator.vibrate ? window.navigator.vibrate.bind(window.navigator) : null;
  window.navigator.vibrate = function(pattern) {
    try {
      var duration = 10;
      if (Array.isArray(pattern) && pattern.length > 0) {
        duration = pattern[0];
      } else if (typeof pattern === 'number') {
        duration = pattern;
      }

      var hapticType = 'light';
      if (duration >= 40) {
        hapticType = 'heavy';
      } else if (duration >= 20) {
        hapticType = 'medium';
      } else if (duration < 15) {
        hapticType = 'selection';
      }

      if (window.PreviewPortNativeBridge) {
        window.PreviewPortNativeBridge.postMessage(JSON.stringify({
          type: 'haptic',
          subtype: hapticType,
          duration: duration
        }));
      }
    } catch (e) {}
    if (originalVibrate) {
      try { originalVibrate(pattern); } catch (e) {}
    }
    return true;
  };

  // 4. Expose explicit window.PreviewPort API for rich developer calls
  window.PreviewPort = {
    haptic: function(type) {
      if (window.PreviewPortNativeBridge) {
        window.PreviewPortNativeBridge.postMessage(JSON.stringify({
          type: 'haptic',
          subtype: type || 'light'
        }));
      }
    },
    setTitle: function(title) {
      if (window.PreviewPortNativeBridge) {
        window.PreviewPortNativeBridge.postMessage(JSON.stringify({
          type: 'title',
          value: title
        }));
      }
    },
    setStatusBarStyle: function(style) {
      if (window.PreviewPortNativeBridge) {
        var isDark = style === 'dark' || (typeof style === 'object' && style.dark === true);
        window.PreviewPortNativeBridge.postMessage(JSON.stringify({
          type: 'theme',
          isDark: isDark
        }));
      }
    }
  };

  // 5. Automatic status bar color detection based on document background / theme-color
  function detectAndSyncTheme() {
    try {
      var isDark = true;
      var metaTheme = document.querySelector('meta[name="theme-color"]');
      if (metaTheme && metaTheme.content) {
        var hex = metaTheme.content.trim().toLowerCase();
        if (hex === '#fff' || hex === '#ffffff' || hex === 'white') {
          isDark = false;
        }
      } else if (document.body) {
        var bg = window.getComputedStyle(document.body).backgroundColor;
        var match = bg.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
        if (match) {
          var r = parseInt(match[1], 10);
          var g = parseInt(match[2], 10);
          var b = parseInt(match[3], 10);
          var lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
          if (lum > 0.55) isDark = false;
        }
      }
      if (window.PreviewPortNativeBridge) {
        window.PreviewPortNativeBridge.postMessage(JSON.stringify({
          type: 'theme',
          isDark: isDark
        }));
      }
    } catch (e) {}
  }
  setTimeout(detectAndSyncTheme, 200);

  // 6. Observe document title changes
  try {
    var titleEl = document.querySelector('title');
    if (titleEl) {
      var observer = new MutationObserver(function() {
        if (window.PreviewPortNativeBridge && document.title) {
          window.PreviewPortNativeBridge.postMessage(JSON.stringify({
            type: 'title',
            value: document.title
          }));
        }
      });
      observer.observe(titleEl, { childList: true, characterData: true, subtree: true });
    }
  } catch (e) {}
})();
''';

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
