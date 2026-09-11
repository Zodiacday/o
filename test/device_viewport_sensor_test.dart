import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/services/device_viewport_sensor.dart';

void main() {
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
        // 667×375 should give same result as 375×667
        expect(DeviceViewportSensor.classifyFormFactor(667, 375), 'standard');
        expect(DeviceViewportSensor.classifyFormFactor(1133, 744), 'tablet');
      });
    });

    group('matchDeviceName', () {
      test('matches known iPhone models', () {
        expect(
          DeviceViewportSensor.matchDeviceName(375, 667, 2.0, 'ios'),
          'iPhone SE',
        );
        expect(
          DeviceViewportSensor.matchDeviceName(393, 852, 3.0, 'ios'),
          'iPhone 14 Pro',
        );
        expect(
          DeviceViewportSensor.matchDeviceName(430, 932, 3.0, 'ios'),
          'iPhone 15 Pro Max',
        );
        expect(
          DeviceViewportSensor.matchDeviceName(440, 956, 3.0, 'ios'),
          'iPhone 16 Pro Max',
        );
      });

      test('matches known Android models', () {
        expect(
          DeviceViewportSensor.matchDeviceName(412, 915, 2.625, 'android'),
          'Pixel 7 / 8',
        );
        expect(
          DeviceViewportSensor.matchDeviceName(412, 883, 3.0, 'android'),
          'Galaxy S24 Ultra',
        );
      });

      test('matches known iPad models', () {
        expect(
          DeviceViewportSensor.matchDeviceName(744, 1133, 2.0, 'ios'),
          'iPad Mini',
        );
        expect(
          DeviceViewportSensor.matchDeviceName(834, 1194, 2.0, 'ios'),
          'iPad Pro 11″',
        );
      });

      test('returns generic fallback for unknown dimensions', () {
        final name = DeviceViewportSensor.matchDeviceName(500, 900, 2.5, 'android');
        expect(name, 'Android 500×900 @2.5x');
      });

      test('returns generic fallback for unknown iOS device', () {
        final name = DeviceViewportSensor.matchDeviceName(999, 1500, 3.0, 'ios');
        expect(name, 'iOS 999×1500 @3.0x');
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
  });
}
