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

  // 2. Native momentum scrolling styles & eliminate WebKit 300ms tap delay & prevent 0-height collapse
  try {
    if (!document.getElementById('__previewport_native_styles')) {
      var style = document.createElement('style');
      style.id = '__previewport_native_styles';
      style.textContent = 'html, body, #root, #__next, flt-glass-pane, flutter-view, [data-v-app] { min-height: 100vh; overscroll-behavior-y: none; -webkit-tap-highlight-color: transparent; touch-action: manipulation; }';
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

  // 8. Signal first-paint ready to native shell (eliminates artificial loading wait)
  try {
    function signalReady() {
      if (window.__previewPortFirstPaintSignaled) return;
      window.__previewPortFirstPaintSignaled = true;
      if (window.PreviewPortNativeBridge) {
        window.PreviewPortNativeBridge.postMessage(JSON.stringify({
          type: 'ready'
        }));
      }
    }

    if (window.requestAnimationFrame) {
      window.requestAnimationFrame(function() {
        window.requestAnimationFrame(signalReady);
      });
    } else {
      setTimeout(signalReady, 40);
    }

    if (document.readyState === 'complete') {
      signalReady();
    } else {
      window.addEventListener('load', signalReady);
    }
  } catch (e) {}

  // 9. The Localhost Auto-Fixer (Rewrites localhost/127.0.0.1 to workstation LAN IP)
  try {
    var currentHost = window.location.hostname;
    // Only rewrite if we are loaded from an actual LAN IP or hostname (not localhost/loopback itself)
    var isLoopbackHost = currentHost === 'localhost' || currentHost === '127.0.0.1' || currentHost === '::1' || !currentHost;
    if (!isLoopbackHost) {
      var localhostRegex = /^(https?|wss?):\/\/(localhost|127\.0\.0\.1)(:\d+)?(\/.*)?$/i;
      var loggedRewrites = {};

      function rewriteUrl(rawUrl) {
        if (!rawUrl || typeof rawUrl !== 'string') return rawUrl;
        var match = rawUrl.match(localhostRegex);
        if (!match) return rawUrl;
        var protocol = match[1];
        var portPart = match[3] || '';
        var pathPart = match[4] || '';
        var rewritten = protocol + '://' + currentHost + portPart + pathPart;

        var logKey = match[2] + portPart + '->' + currentHost + portPart;
        if (!loggedRewrites[logKey]) {
          loggedRewrites[logKey] = true;
          if (window.PreviewPortNativeBridge) {
            window.PreviewPortNativeBridge.postMessage(JSON.stringify({
              type: 'console',
              level: 'info',
              message: '⚡ [PreviewPort] Auto-routed ' + match[2] + portPart + ' -> ' + currentHost + portPart
            }));
          }
        }
        return rewritten;
      }

      // Intercept window.fetch
      if (window.fetch) {
        var originalFetch = window.fetch;
        window.fetch = function(input, init) {
          try {
            if (typeof input === 'string') {
              input = rewriteUrl(input);
            } else if (input instanceof URL) {
              input = new URL(rewriteUrl(input.href));
            } else if (input && typeof input === 'object' && input.url) {
              var rewritten = rewriteUrl(input.url);
              if (rewritten !== input.url) {
                input = new Request(rewritten, input);
              }
            }
          } catch (e) {}
          return originalFetch.call(this, input, init);
        };
      }

      // Intercept XMLHttpRequest
      if (window.XMLHttpRequest && window.XMLHttpRequest.prototype && window.XMLHttpRequest.prototype.open) {
        var originalXhrOpen = window.XMLHttpRequest.prototype.open;
        window.XMLHttpRequest.prototype.open = function(method, url) {
          try {
            if (typeof url === 'string') {
              url = rewriteUrl(url);
            }
          } catch (e) {}
          var args = Array.prototype.slice.call(arguments);
          args[1] = url;
          return originalXhrOpen.apply(this, args);
        };
      }

      // Intercept window.WebSocket
      if (window.WebSocket) {
        var OriginalWebSocket = window.WebSocket;
        var ProxiedWebSocket = function(url, protocols) {
          var targetUrl = rewriteUrl(url);
          return protocols ? new OriginalWebSocket(targetUrl, protocols) : new OriginalWebSocket(targetUrl);
        };
        ProxiedWebSocket.prototype = OriginalWebSocket.prototype;
        ProxiedWebSocket.CONNECTING = OriginalWebSocket.CONNECTING;
        ProxiedWebSocket.OPEN = OriginalWebSocket.OPEN;
        ProxiedWebSocket.CLOSING = OriginalWebSocket.CLOSING;
        ProxiedWebSocket.CLOSED = OriginalWebSocket.CLOSED;
        window.WebSocket = ProxiedWebSocket;
      }

      // Intercept window.EventSource
      if (window.EventSource) {
        var OriginalEventSource = window.EventSource;
        var ProxiedEventSource = function(url, eventSourceInitDict) {
          var targetUrl = rewriteUrl(url);
          return eventSourceInitDict ? new OriginalEventSource(targetUrl, eventSourceInitDict) : new OriginalEventSource(targetUrl);
        };
        ProxiedEventSource.prototype = OriginalEventSource.prototype;
        ProxiedEventSource.CONNECTING = OriginalEventSource.CONNECTING;
        ProxiedEventSource.OPEN = OriginalEventSource.OPEN;
        ProxiedEventSource.CLOSED = OriginalEventSource.CLOSED;
        window.EventSource = ProxiedEventSource;
      }
    }
  } catch (e) {}

  // 10. In-App Network Inspector (Telemetry for fetch & XMLHttpRequest)
  try {
    function emitNetworkEvent(req) {
      if (!window.PreviewPortNativeBridge) return;
      try {
        window.PreviewPortNativeBridge.postMessage(JSON.stringify({
          type: 'network',
          request: req
        }));
      } catch (e) {}
    }

    // Intercept fetch
    if (window.fetch) {
      var prevFetch = window.fetch;
      window.fetch = function(input, init) {
        var start = window.performance ? window.performance.now() : Date.now();
        var rawUrl = '';
        var method = 'GET';

        try {
          if (typeof input === 'string') {
            rawUrl = input;
          } else if (input instanceof URL) {
            rawUrl = input.href;
          } else if (input && typeof input === 'object') {
            rawUrl = input.url || '';
            if (input.method) method = input.method.toUpperCase();
          }
          if (init && init.method) {
            method = init.method.toUpperCase();
          }
        } catch (e) {}

        return prevFetch.call(this, input, init).then(function(res) {
          try {
            var duration = Math.round((window.performance ? window.performance.now() : Date.now()) - start);
            emitNetworkEvent({
              id: 'req_' + Math.random().toString(36).substr(2, 9),
              url: (res && res.url) ? res.url : rawUrl,
              method: method,
              status: (res && typeof res.status === 'number') ? res.status : 200,
              statusText: (res && res.statusText) ? res.statusText : 'OK',
              durationMs: duration,
              initiator: 'fetch',
              timestamp: Date.now()
            });
          } catch (e) {}
          return res;
        }).catch(function(err) {
          try {
            var duration = Math.round((window.performance ? window.performance.now() : Date.now()) - start);
            emitNetworkEvent({
              id: 'req_' + Math.random().toString(36).substr(2, 9),
              url: rawUrl,
              method: method,
              status: 0,
              statusText: (err && err.message) ? err.message : 'Network Error',
              durationMs: duration,
              initiator: 'fetch',
              timestamp: Date.now()
            });
          } catch (e) {}
          throw err;
        });
      };
    }

    // Intercept XMLHttpRequest
    if (window.XMLHttpRequest && window.XMLHttpRequest.prototype && window.XMLHttpRequest.prototype.open && window.XMLHttpRequest.prototype.send) {
      var prevXhrOpen = window.XMLHttpRequest.prototype.open;
      var prevXhrSend = window.XMLHttpRequest.prototype.send;

      window.XMLHttpRequest.prototype.open = function(method, url) {
        try {
          this.__pp_method = (method || 'GET').toUpperCase();
          this.__pp_url = typeof url === 'string' ? url : String(url);
        } catch (e) {}
        return prevXhrOpen.apply(this, arguments);
      };

      window.XMLHttpRequest.prototype.send = function() {
        var xhr = this;
        var start = window.performance ? window.performance.now() : Date.now();

        function onComplete() {
          if (xhr.__pp_completed) return;
          xhr.__pp_completed = true;
          try {
            var duration = Math.round((window.performance ? window.performance.now() : Date.now()) - start);
            var status = xhr.status || 0;
            var statusText = xhr.statusText || (status >= 200 && status < 300 ? 'OK' : 'Error');
            var finalUrl = xhr.responseURL || xhr.__pp_url || '';
            emitNetworkEvent({
              id: 'req_' + Math.random().toString(36).substr(2, 9),
              url: finalUrl,
              method: xhr.__pp_method || 'GET',
              status: status,
              statusText: statusText,
              durationMs: duration,
              initiator: 'xhr',
              timestamp: Date.now()
            });
          } catch (e) {}
        }

        try {
          if (xhr.addEventListener) {
            xhr.addEventListener('loadend', onComplete);
            xhr.addEventListener('error', onComplete);
            xhr.addEventListener('abort', onComplete);
          } else {
            var origOnReadyState = xhr.onreadystatechange;
            xhr.onreadystatechange = function() {
              if (xhr.readyState === 4) {
                onComplete();
              }
              if (origOnReadyState) origOnReadyState.apply(this, arguments);
            };
          }
        } catch (e) {}

        return prevXhrSend.apply(this, arguments);
      };
    }
  } catch (e) {}

  // 11. Global JavaScript & Promise Error Catcher
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
