import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/services/device_viewport_sensor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DeviceViewportSensor.resetCache();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.previewport/device_info'),
      null,
    );
    DeviceViewportSensor.resetCache();
  });

  group('DeviceViewportSensor', () {
    group('classifyFormFactor', () {
      test('classifies compact devices (short side <= 360)', () {
        expect(DeviceViewportSensor.classifyFormFactor(375, 667), 'standard');
        expect(DeviceViewportSensor.classifyFormFactor(360, 780), 'compact');
        expect(DeviceViewportSensor.classifyFormFactor(320, 568), 'compact');
      });

      test('classifies standard devices (361..419)', () {
        expect(DeviceViewportSensor.classifyFormFactor(390, 844), 'standard');
        expect(DeviceViewportSensor.classifyFormFactor(393, 852), 'standard');
        expect(DeviceViewportSensor.classifyFormFactor(412, 915), 'standard');
      });

      test('classifies large devices (short side >= 420)', () {
        expect(DeviceViewportSensor.classifyFormFactor(430, 932), 'large');
        expect(DeviceViewportSensor.classifyFormFactor(440, 956), 'large');
      });

      test('classifies tablets (short side >= 600 or long side >= 1000)', () {
        expect(DeviceViewportSensor.classifyFormFactor(744, 1133), 'tablet');
        expect(DeviceViewportSensor.classifyFormFactor(820, 1180), 'tablet');
        expect(DeviceViewportSensor.classifyFormFactor(1024, 1366), 'tablet');
      });

      test('handles landscape orientation correctly', () {
        expect(DeviceViewportSensor.classifyFormFactor(667, 375), 'standard');
        expect(DeviceViewportSensor.classifyFormFactor(1133, 744), 'tablet');
      });
    });

    group('estimateCornerRadius', () {
      test('returns flat-screen radius for no safe area', () {
        expect(
          DeviceViewportSensor.estimateCornerRadius(2.0, false, 'ios'),
          18.0,
        );
        expect(
          DeviceViewportSensor.estimateCornerRadius(2.0, false, 'android'),
          12.0,
        );
      });

      test('returns rounded radius for modern iOS with safe area', () {
        expect(
          DeviceViewportSensor.estimateCornerRadius(3.0, true, 'ios'),
          47.0,
        );
        expect(
          DeviceViewportSensor.estimateCornerRadius(2.0, true, 'ios'),
          39.0,
        );
      });

      test('returns rounded radius for modern Android with safe area', () {
        expect(
          DeviceViewportSensor.estimateCornerRadius(3.0, true, 'android'),
          28.0,
        );
      });
    });

    group('detectSync', () {
      testWidgets('builds native profile from MediaQuery context', (tester) async {
        late BuildContext capturedContext;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(393, 852),
              padding: EdgeInsets.only(top: 59, bottom: 34),
              devicePixelRatio: 3.0,
            ),
            child: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox();
              },
            ),
          ),
        );

        final profile = DeviceViewportSensor.detectSync(capturedContext);
        expect(profile.id, 'native');
        expect(profile.isNativeDevice, isTrue);
        expect(profile.isNative, isTrue);
        expect(profile.width, 393);
        expect(profile.height, 852);
        expect(profile.topInset, 59);
        expect(profile.bottomInset, 34);
        expect(profile.devicePixelRatio, 3.0);
        expect(profile.formFactor, 'standard');
      });
    });

    group('detect with platform channel', () {
      testWidgets('reads authoritative device model name from platform channel', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.previewport/device_info'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getDeviceInfo') {
              return {
                'model': 'iPhone 16 Pro',
                'identifier': 'iPhone17,3',
                'osVersion': '18.2',
                'platform': 'ios',
              };
            }
            return null;
          },
        );

        late BuildContext capturedContext;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(402, 874),
              padding: EdgeInsets.only(top: 59, bottom: 34),
              devicePixelRatio: 3.0,
            ),
            child: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox();
              },
            ),
          ),
        );

        final profile = await DeviceViewportSensor.detect(capturedContext);
        expect(profile.name, 'iPhone 16 Pro');
        expect(profile.isNativeDevice, isTrue);
        expect(profile.width, 402);
        expect(profile.height, 874);

        // Subsequent call should use cache without hitting channel again
        final cachedProfile = DeviceViewportSensor.detectSync(capturedContext);
        expect(cachedProfile.name, 'iPhone 16 Pro');
      });

      testWidgets('reads Android device model name correctly', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.previewport/device_info'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'getDeviceInfo') {
              return {
                'model': 'Google Pixel 9',
                'identifier': 'google/tokay',
                'osVersion': '15',
                'platform': 'android',
              };
            }
            return null;
          },
        );

        late BuildContext capturedContext;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.only(top: 32, bottom: 16),
              devicePixelRatio: 2.625,
            ),
            child: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox();
              },
            ),
          ),
        );

        final profile = await DeviceViewportSensor.detect(capturedContext);
        expect(profile.name, 'Google Pixel 9');
      });

      testWidgets('falls back gracefully when channel throws PlatformException', (tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.previewport/device_info'),
          (MethodCall methodCall) async {
            throw PlatformException(code: 'UNAVAILABLE', message: 'Not supported');
          },
        );

        late BuildContext capturedContext;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.zero,
              devicePixelRatio: 2.0,
            ),
            child: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox();
              },
            ),
          ),
        );

        final profile = await DeviceViewportSensor.detect(capturedContext);
        expect(profile.isNativeDevice, isTrue);
        // Falls back to generic format
        expect(profile.name, contains('412×915'));
      });

      testWidgets('resetCache clears cached info', (tester) async {
        int callCount = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('com.previewport/device_info'),
          (MethodCall methodCall) async {
            callCount++;
            return {'model': 'Test Device $callCount'};
          },
        );

        late BuildContext capturedContext;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(375, 667)),
            child: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox();
              },
            ),
          ),
        );

        final p1 = await DeviceViewportSensor.detect(capturedContext);
        expect(p1.name, 'Test Device 1');
        expect(callCount, 1);

        // Without reset, cache returns same
        final p2 = await DeviceViewportSensor.detect(capturedContext);
        expect(p2.name, 'Test Device 1');
        expect(callCount, 1);

        // After reset, channel is called again
        DeviceViewportSensor.resetCache();
        final p3 = await DeviceViewportSensor.detect(capturedContext);
        expect(p3.name, 'Test Device 2');
        expect(callCount, 2);
      });
    });
  });
}
