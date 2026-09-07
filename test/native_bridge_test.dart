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

    test('parses theme synchronization events', () {
      bool? isDarkReceived;
      final handler = NativeBridgeHandler(
        onThemeChanged: (isDark) => isDarkReceived = isDark,
      );

      handler.handleMessage('{"type":"theme","isDark":true}');
      expect(isDarkReceived, isTrue);

      handler.handleMessage('{"type":"theme","isDark":false}');
      expect(isDarkReceived, isFalse);
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
