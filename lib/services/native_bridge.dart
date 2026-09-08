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

    final insetsPreamble = '''
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
})();
''';

    return insetsPreamble + _coreScript;
  }

  /// Default baseline script for static evaluation or testing.
  static String get injectionScript => buildInjectionScript();

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

  static const String _coreScript = r'''
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
      if (document.head) document.head.appendChild(metaViewport);
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
      if (document.head) document.head.appendChild(style);
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

  // 4. Expose explicit window.PreviewPort API and ExpoStatusBar compatibility
  window.PreviewPort = window.PreviewPort || {};
  window.PreviewPort.haptic = function(type) {
    if (window.PreviewPortNativeBridge) {
      window.PreviewPortNativeBridge.postMessage(JSON.stringify({
        type: 'haptic',
        subtype: type || 'light'
      }));
    }
  };
  window.PreviewPort.setTitle = function(title) {
    if (window.PreviewPortNativeBridge) {
      window.PreviewPortNativeBridge.postMessage(JSON.stringify({
        type: 'title',
        value: title
      }));
    }
  };
  window.PreviewPort.setStatusBarStyle = function(style) {
    if (window.PreviewPortNativeBridge) {
      var isDark = style === 'dark' || (typeof style === 'object' && style.dark === true);
      window.PreviewPortNativeBridge.postMessage(JSON.stringify({
        type: 'theme',
        isDark: isDark
      }));
    }
  };

  window.ExpoStatusBar = {
    setStyle: function(style) {
      window.PreviewPort.setStatusBarStyle(style);
    }
  };

  // 5. Network Conditioning (offline, 3g, normal)
  window.__previewPortNetworkState = 'normal';
  window.PreviewPort.setNetworkCondition = function(condition) {
    window.__previewPortNetworkState = condition || 'normal';
    if (condition === 'offline') {
      try { window.dispatchEvent(new Event('offline')); } catch (e) {}
    } else {
      try { window.dispatchEvent(new Event('online')); } catch (e) {}
    }
  };

  try {
    var originalFetch = window.fetch;
    if (originalFetch) {
      window.fetch = function(input, init) {
        if (window.__previewPortNetworkState === 'offline') {
          return Promise.reject(new TypeError('Failed to fetch (PreviewPort offline mode)'));
        }
        if (window.__previewPortNetworkState === '3g') {
          return new Promise(function(resolve, reject) {
            setTimeout(function() {
              originalFetch(input, init).then(resolve, reject);
            }, 500);
          });
        }
        return originalFetch(input, init);
      };
    }

    var originalXhrSend = XMLHttpRequest.prototype.send;
    XMLHttpRequest.prototype.send = function(body) {
      var xhr = this;
      if (window.__previewPortNetworkState === 'offline') {
        setTimeout(function() {
          xhr.dispatchEvent(new ProgressEvent('error'));
        }, 10);
        return;
      }
      if (window.__previewPortNetworkState === '3g') {
        setTimeout(function() {
          try { originalXhrSend.call(xhr, body); } catch (e) {}
        }, 500);
        return;
      }
      return originalXhrSend.call(xhr, body);
    };
  } catch (e) {}

  // 6. Geo-Location & GPS Mocking
  window.__previewPortMockLocation = null;
  window.PreviewPort.setMockLocation = function(loc) {
    window.__previewPortMockLocation = loc;
  };

  try {
    if (navigator.geolocation) {
      var origGetCurrentPosition = navigator.geolocation.getCurrentPosition.bind(navigator.geolocation);
      navigator.geolocation.getCurrentPosition = function(success, error, options) {
        if (window.__previewPortMockLocation && typeof success === 'function') {
          var m = window.__previewPortMockLocation;
          var pos = {
            coords: {
              latitude: m.latitude,
              longitude: m.longitude,
              altitude: m.altitude || 15.0,
              accuracy: m.accuracy || 5.0,
              altitudeAccuracy: 5.0,
              heading: null,
              speed: null
            },
            timestamp: Date.now()
          };
          setTimeout(function() { success(pos); }, 15);
          return;
        }
        return origGetCurrentPosition(success, error, options);
      };

      var origWatchPosition = navigator.geolocation.watchPosition.bind(navigator.geolocation);
      navigator.geolocation.watchPosition = function(success, error, options) {
        if (window.__previewPortMockLocation && typeof success === 'function') {
          var m = window.__previewPortMockLocation;
          var pos = {
            coords: {
              latitude: m.latitude,
              longitude: m.longitude,
              altitude: m.altitude || 15.0,
              accuracy: m.accuracy || 5.0,
              altitudeAccuracy: 5.0,
              heading: null,
              speed: null
            },
            timestamp: Date.now()
          };
          setTimeout(function() { success(pos); }, 15);
          return 9999;
        }
        return origWatchPosition(success, error, options);
      };
    }
  } catch (e) {}

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
  // 7. Pipe console logs to native bridge for Mini-Terminal
  try {
    ['log', 'warn', 'error'].forEach(function(lvl) {
      var orig = console[lvl];
      console[lvl] = function() {
        try {
          var args = Array.prototype.slice.call(arguments);
          var msg = args.map(function(a) {
            return typeof a === 'object' ? JSON.stringify(a) : String(a);
          }).join(' ');
          if (window.PreviewPortNativeBridge) {
            window.PreviewPortNativeBridge.postMessage(JSON.stringify({
              type: 'console',
              level: lvl === 'log' ? 'info' : lvl,
              message: msg
            }));
          }
        } catch (e) {}
        if (orig) orig.apply(console, arguments);
      };
    });
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
