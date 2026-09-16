/// JavaScript installed into each preview to expose PreviewPort's browser API.
///
/// Kept separate from message dispatch so the bridge protocol remains readable.
const String nativeBridgeCoreScript = r'''
(function() {
  if (window.__previewPortBridgeInjected) return;
  window.__previewPortBridgeInjected = true;

  // 1. Ensure viewport tag exists without mutating existing configs to prevent WebKit rescaling glitches
  try {
    var metaViewport = document.querySelector('meta[name="viewport"]');
    if (!metaViewport) {
      metaViewport = document.createElement('meta');
      metaViewport.name = 'viewport';
      metaViewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
      if (document.head) document.head.appendChild(metaViewport);
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

  // 5. Automatic status bar and safe-area background color detection
  function detectAndSyncTheme() {
    try {
      var isDark = true;
      var dominantColor = '';
      var metaTheme = document.querySelector('meta[name="theme-color"]');
      if (metaTheme && metaTheme.content) {
        dominantColor = metaTheme.content.trim();
      } else {
        var bodyBg = document.body ? window.getComputedStyle(document.body).backgroundColor : null;
        var htmlBg = document.documentElement ? window.getComputedStyle(document.documentElement).backgroundColor : null;
        if (bodyBg && bodyBg !== 'rgba(0, 0, 0, 0)' && bodyBg !== 'transparent') {
          dominantColor = bodyBg;
        } else if (htmlBg && htmlBg !== 'rgba(0, 0, 0, 0)' && htmlBg !== 'transparent') {
          dominantColor = htmlBg;
        }
      }

      if (dominantColor) {
        var rgbMatch = dominantColor.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
        if (rgbMatch) {
          var r = parseInt(rgbMatch[1], 10);
          var g = parseInt(rgbMatch[2], 10);
          var b = parseInt(rgbMatch[3], 10);
          var lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
          if (lum > 0.55) isDark = false;
        } else if (dominantColor.startsWith('#')) {
          var hex = dominantColor.replace('#', '');
          if (hex.length === 3) {
            hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
          }
          if (hex.length === 6) {
            var r = parseInt(hex.substring(0, 2), 16);
            var g = parseInt(hex.substring(2, 4), 16);
            var b = parseInt(hex.substring(4, 6), 16);
            var lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
            if (lum > 0.55) isDark = false;
          }
        } else if (dominantColor.toLowerCase() === 'white') {
          isDark = false;
        }
      }

      if (window.PreviewPortNativeBridge) {
        var payload = {
          type: 'theme',
          isDark: isDark
        };
        if (dominantColor) {
          payload.color = dominantColor;
        }
        window.PreviewPortNativeBridge.postMessage(JSON.stringify(payload));
      }
    } catch (e) {}
  }
  setTimeout(detectAndSyncTheme, 150);
  setTimeout(detectAndSyncTheme, 600);
  setTimeout(detectAndSyncTheme, 1600);

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
