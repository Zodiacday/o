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

      expect(find.text('Device Viewport Simulator'), findsOneWidget);
      expect(find.text('Native Device'), findsOneWidget);
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
  });
}
