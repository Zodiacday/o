import 'dart:ui' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/services/native_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeBridgeHandler', () {
    test('injectionScript includes required bridge definitions', () {
      expect(NativeBridgeHandler.injectionScript, contains('PreviewPortNativeBridge'));
      expect(NativeBridgeHandler.injectionScript, contains('window.navigator.vibrate'));
      expect(NativeBridgeHandler.injectionScript, contains('window.PreviewPort'));
      expect(NativeBridgeHandler.injectionScript, contains('MutationObserver'));
      expect(NativeBridgeHandler.injectionScript, contains('viewport-fit=cover'));
      expect(NativeBridgeHandler.injectionScript, contains('overscroll-behavior-y'));
      expect(NativeBridgeHandler.injectionScript, contains('setStatusBarStyle'));
      expect(NativeBridgeHandler.injectionScript, contains('window.safeAreaInsets'));
      expect(NativeBridgeHandler.injectionScript, contains('ExpoStatusBar'));
      expect(NativeBridgeHandler.injectionScript, contains('setNetworkCondition'));
      expect(NativeBridgeHandler.injectionScript, contains('setMockLocation'));
    });

    test('buildSetNetworkConditionScript formats JS statement correctly', () {
      final scriptOffline = NativeBridgeHandler.buildSetNetworkConditionScript('offline');
      expect(scriptOffline, contains('window.PreviewPort.setNetworkCondition("offline")'));

      final script3G = NativeBridgeHandler.buildSetNetworkConditionScript('3g');
      expect(script3G, contains('window.PreviewPort.setNetworkCondition("3g")'));
    });

    test('buildSetMockLocationScript formats custom and null coordinates correctly', () {
      final scriptMock = NativeBridgeHandler.buildSetMockLocationScript(
        latitude: 37.3349,
        longitude: -122.0090,
      );
      expect(scriptMock, contains('latitude: 37.334900'));
      expect(scriptMock, contains('longitude: -122.009000'));

      final scriptClear = NativeBridgeHandler.buildSetMockLocationScript(
        latitude: null,
        longitude: null,
      );
      expect(scriptClear, contains('window.PreviewPort.setMockLocation(null)'));
    });

    test('buildInjectionScript populates hardware metrics and Dynamic Island detection', () {
      final script = NativeBridgeHandler.buildInjectionScript(
        topInset: 59.0,
        bottomInset: 34.0,
        leftInset: 0.0,
        rightInset: 0.0,
        width: 393.0,
        height: 852.0,
        pixelRatio: 3.0,
        platform: 'ios',
      );

      expect(script, contains('top: 59.0'));
      expect(script, contains('bottom: 34.0'));
      expect(script, contains('--safe-area-inset-top: 59.0px'));
      expect(script, contains('--safe-area-inset-bottom: 34.0px'));
      expect(script, contains('hasDynamicIsland: true'));
      expect(script, contains('hasNotch: true'));
      expect(script, contains("platform: 'ios'"));
    });

    test('parses and triggers haptic feedback events', () {
      NativeHapticType? lastTriggered;
      final handler = NativeBridgeHandler(
        onHapticTriggered: (type) => lastTriggered = type,
      );

      handler.handleMessage('{"type":"haptic","subtype":"selection"}');
      expect(lastTriggered, NativeHapticType.selection);

      handler.handleMessage('{"type":"haptic","subtype":"light"}');
      expect(lastTriggered, NativeHapticType.light);

      handler.handleMessage('{"type":"haptic","subtype":"medium"}');
      expect(lastTriggered, NativeHapticType.medium);

      handler.handleMessage('{"type":"haptic","subtype":"heavy"}');
      expect(lastTriggered, NativeHapticType.heavy);

      handler.handleMessage('{"type":"haptic","subtype":"vibrate"}');
      expect(lastTriggered, NativeHapticType.vibrate);

      handler.handleMessage('{"type":"haptic","subtype":"unknown"}');
      expect(lastTriggered, NativeHapticType.light);
    });

    test('parses title synchronization events', () {
      String? updatedTitle;
      final handler = NativeBridgeHandler(
        onTitleChanged: (title) => updatedTitle = title,
      );

      handler.handleMessage('{"type":"title","value":"My Flutter App"}');
      expect(updatedTitle, 'My Flutter App');

      handler.handleMessage('{"type":"title","value":"   "}');
      expect(updatedTitle, 'My Flutter App'); // unchanged for empty
    });

    test('parses theme synchronization events and dominant colors', () {
      bool? isDarkReceived;
      Color? colorReceived;
      final handler = NativeBridgeHandler(
        onThemeChanged: (isDark) => isDarkReceived = isDark,
        onThemeColorDetected: (color) => colorReceived = color,
      );

      handler.handleMessage('{"type":"theme","isDark":true,"color":"#121212"}');
      expect(isDarkReceived, isTrue);
      expect(colorReceived, const Color(0xFF121212));

      handler.handleMessage('{"type":"theme","isDark":false,"color":"rgb(255, 255, 255)"}');
      expect(isDarkReceived, isFalse);
      expect(colorReceived, const Color(0xFFFFFFFF));
    });

    test('parseCssColor parses various CSS color notations correctly', () {
      expect(NativeBridgeHandler.parseCssColor('#fff'), const Color(0xFFFFFFFF));
      expect(NativeBridgeHandler.parseCssColor('#00E5FF'), const Color(0xFF00E5FF));
      expect(NativeBridgeHandler.parseCssColor('white'), const Color(0xFFFFFFFF));
      expect(NativeBridgeHandler.parseCssColor('black'), const Color(0xFF000000));
      expect(NativeBridgeHandler.parseCssColor('rgb(18, 18, 18)'), const Color(0xFF121212));
      expect(NativeBridgeHandler.parseCssColor('rgba(0, 229, 255, 1.0)'), const Color(0xFF00E5FF));
      expect(NativeBridgeHandler.parseCssColor('transparent'), isNull);
      expect(NativeBridgeHandler.parseCssColor(''), isNull);
      expect(NativeBridgeHandler.parseCssColor('invalid'), isNull);
    });

    test('ignores malformed or unexpected payloads gracefully', () {
      var triggered = false;
      final handler = NativeBridgeHandler(
        onHapticTriggered: (_) => triggered = true,
        onTitleChanged: (_) => triggered = true,
        onThemeChanged: (_) => triggered = true,
      );

      handler.handleMessage('');
      handler.handleMessage('not a json');
      handler.handleMessage('{"random":"data"}');
      handler.handleMessage('123');

      expect(triggered, isFalse);
    });
  });
}
