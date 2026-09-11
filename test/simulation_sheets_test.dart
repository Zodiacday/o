import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/widgets/location_mock_sheet.dart';
import 'package:previewport/widgets/viewport_switcher_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationMockSheet', () {
    testWidgets('renders all default presets and selects one', (tester) async {
      MockLocationPreset? selectedPreset;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationMockSheet(
              selected: defaultLocationPresets.first,
              onSelect: (preset) => selectedPreset = preset,
              onCustom: (lat, lng, name) {},
            ),
          ),
        ),
      );

      expect(find.text('Simulate Location'), findsOneWidget);
      expect(find.text('Real Hardware GPS'), findsOneWidget);
      expect(find.text('Apple Park, Cupertino'), findsOneWidget);
      expect(find.text('Shibuya, Tokyo'), findsOneWidget);

      await tester.tap(find.text('Shibuya, Tokyo'));
      await tester.pumpAndSettle();

      expect(selectedPreset, isNotNull);
      expect(selectedPreset!.id, 'tokyo');
      expect(selectedPreset!.latitude, 35.6595);
      expect(selectedPreset!.longitude, 139.7004);
    });
  });

  group('ViewportSwitcherSheet', () {
    testWidgets('renders device profiles and selects simulated device', (tester) async {
      SimulatedDeviceProfile? selectedProfile;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewportSwitcherSheet(
              selected: defaultDeviceProfiles.first,
              onSelect: (profile) => selectedProfile = profile,
            ),
          ),
        ),
      );

      expect(find.text('Device Viewport'), findsOneWidget);
      expect(find.text('iPhone SE (Compact 4.7")'), findsOneWidget);
      expect(find.text('Android Punch-Hole (6.2")'), findsOneWidget);
      expect(find.text('iPad Mini (Tablet 8.3")'), findsOneWidget);

      await tester.tap(find.text('iPhone SE (Compact 4.7")'));
      await tester.pumpAndSettle();

      expect(selectedProfile, isNotNull);
      expect(selectedProfile!.id, 'iphone_se');
      expect(selectedProfile!.width, 375);
      expect(selectedProfile!.height, 667);
      expect(selectedProfile!.topInset, 20);
    });

    testWidgets('shows "YOUR DEVICE" section when nativeDevice is provided', (tester) async {
      final nativeProfile = SimulatedDeviceProfile(
        id: 'native',
        name: 'iPhone 14 Pro',
        description: '393 × 852 pt · @3x · Dynamic Island · Standard',
        width: 393,
        height: 852,
        topInset: 59,
        bottomInset: 34,
        cornerRadius: 47,
        hasDynamicIsland: true,
        icon: Icons.phone_iphone_rounded,
        isNativeDevice: true,
        devicePixelRatio: 3.0,
        formFactor: 'standard',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ViewportSwitcherSheet(
                selected: nativeProfile,
                nativeDevice: nativeProfile,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      );

      // Section labels
      expect(find.text('YOUR DEVICE'), findsOneWidget);
      expect(find.text('SIMULATE ANOTHER'), findsOneWidget);

      // Native device details
      expect(find.text('iPhone 14 Pro'), findsOneWidget);
      expect(find.text('393 × 852 pt · @3x · Dynamic Island · Standard'), findsOneWidget);

      // Simulated profiles still present
      expect(find.text('iPhone SE (Compact 4.7")'), findsOneWidget);
      expect(find.text('Android Punch-Hole (6.2")'), findsOneWidget);
      expect(find.text('iPad Mini (Tablet 8.3")'), findsOneWidget);
    });

    testWidgets('shows form-factor badge for non-standard devices', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ViewportSwitcherSheet(
                selected: defaultDeviceProfiles.first,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      );

      // iPhone SE has formFactor 'compact', iPad Mini has 'tablet'
      expect(find.text('COMPACT'), findsOneWidget);
      expect(find.text('TABLET'), findsOneWidget);
    });

    testWidgets('tapping native device tile calls onSelect with native profile', (tester) async {
      SimulatedDeviceProfile? selectedProfile;

      final nativeProfile = SimulatedDeviceProfile(
        id: 'native',
        name: 'Pixel 9',
        description: '412 × 922 pt · @2.6x · Notch · Standard',
        width: 412,
        height: 922,
        topInset: 36,
        bottomInset: 16,
        cornerRadius: 28,
        hasNotch: true,
        icon: Icons.smartphone_rounded,
        isNativeDevice: true,
        devicePixelRatio: 2.625,
        formFactor: 'standard',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ViewportSwitcherSheet(
                selected: simulatedDeviceProfiles.first, // SE selected
                nativeDevice: nativeProfile,
                onSelect: (profile) => selectedProfile = profile,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pixel 9'));
      await tester.pumpAndSettle();

      expect(selectedProfile, isNotNull);
      expect(selectedProfile!.isNative, isTrue);
      expect(selectedProfile!.name, 'Pixel 9');
      expect(selectedProfile!.width, 412);
    });

    test('SimulatedDeviceProfile.isNative reflects isNativeDevice flag', () {
      const native = SimulatedDeviceProfile(
        id: 'native',
        name: 'Test',
        description: 'test',
        width: 393,
        height: 852,
        icon: Icons.phone_iphone_rounded,
        isNativeDevice: true,
      );
      const simulated = SimulatedDeviceProfile(
        id: 'iphone_se',
        name: 'SE',
        description: 'test',
        width: 375,
        height: 667,
        icon: Icons.phone_android_rounded,
      );

      expect(native.isNative, isTrue);
      expect(simulated.isNative, isFalse);
    });
  });
}
