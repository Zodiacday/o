/// JavaScript installed into previews to expose PreviewPort's non-invasive browser API.
///
/// Intentionally minimal: ZERO monkey-patching of window.fetch, window.WebSocket,
/// or XMLHttpRequest, and ZERO CSS overrides on Flutter layout elements.
const String nativeBridgeCoreScript = r'''
(function() {
  if (window.__previewPortBridgeInjected) return;
  window.__previewPortBridgeInjected = true;

  // 1. Ensure viewport tag exists if not present (does not mutate existing tags)
  try {
    var metaViewport = document.querySelector('meta[name="viewport"]');
    if (!metaViewport) {
      metaViewport = document.createElement('meta');
      metaViewport.name = 'viewport';
      metaViewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
      if (document.head) document.head.appendChild(metaViewport);
    }
  } catch (e) {}

  // 2. Expose explicit window.PreviewPort API and ExpoStatusBar compatibility
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
  window.PreviewPort.setStatusBarStyle = function(style, color) {
    if (window.PreviewPortNativeBridge) {
      var isDark = style === 'dark' || (typeof style === 'object' && style.dark === true);
      var payload = {
        type: 'theme',
        isDark: isDark
      };
      if (typeof color === 'string') {
        payload.color = color;
      }
      window.PreviewPortNativeBridge.postMessage(JSON.stringify(payload));
    }
  };

  window.ExpoStatusBar = {
    setStyle: function(style) {
      window.PreviewPort.setStatusBarStyle(style);
    }
  };

  // 3. Passive theme-color detection (does not mutate DOM or styles)
  function detectAndSyncTheme() {
    try {
      var dominantColor = '';
      var metaTheme = document.querySelector('meta[name="theme-color"]');
      if (metaTheme && metaTheme.content) {
        dominantColor = metaTheme.content.trim();
      }
      if (dominantColor && window.PreviewPortNativeBridge) {
        var isDark = true;
        var rgbMatch = dominantColor.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
        if (rgbMatch) {
          var r = parseInt(rgbMatch[1], 10);
          var g = parseInt(rgbMatch[2], 10);
          var b = parseInt(rgbMatch[3], 10);
          var lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
          if (lum > 0.55) isDark = false;
        } else if (dominantColor.startsWith('#')) {
          var hex = dominantColor.replace('#', '');
          if (hex.length === 3) hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
          if (hex.length === 6) {
            var r = parseInt(hex.substring(0, 2), 16);
            var g = parseInt(hex.substring(2, 4), 16);
            var b = parseInt(hex.substring(4, 6), 16);
            var lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
            if (lum > 0.55) isDark = false;
          }
        }
        window.PreviewPortNativeBridge.postMessage(JSON.stringify({
          type: 'theme',
          isDark: isDark,
          color: dominantColor
        }));
      }
    } catch (e) {}
  }
  setTimeout(detectAndSyncTheme, 300);
  setTimeout(detectAndSyncTheme, 1200);

  // 4. Observe document title changes passively
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

  // 5. Passive Global JavaScript & Promise Error Catcher
  try {
    window.addEventListener('error', function(e) {
      if (!window.PreviewPortNativeBridge) return;
      try {
        var msg = e.message || 'Unknown JavaScript Error';
        var src = e.filename || '';
        var line = e.lineno || 0;
        window.PreviewPortNativeBridge.postMessage(JSON.stringify({
          type: 'fatal_startup_error',
          message: msg,
          file: src,
          line: line
        }));
      } catch (_) {}
    });

    window.addEventListener('unhandledrejection', function(e) {
      if (!window.PreviewPortNativeBridge) return;
      try {
        var reason = e.reason;
        var msg = 'Unhandled Promise Rejection';
        if (typeof reason === 'string') {
          msg = reason;
        } else if (reason && reason.message) {
          msg = reason.message;
        } else if (reason && reason.toString) {
          msg = reason.toString();
        }
        window.PreviewPortNativeBridge.postMessage(JSON.stringify({
          type: 'fatal_startup_error',
          message: msg
        }));
      } catch (_) {}
    });
  } catch (e) {}
})();
''';
