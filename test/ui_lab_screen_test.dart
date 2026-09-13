import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/screens/ui_lab_screen.dart';
import 'package:previewport/widgets/floating_ghost_capsule.dart';
import 'package:previewport/widgets/floating_navbar.dart';
import 'package:previewport/widgets/liquid_dev_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UI Lab Screen & Sandbox Tests', () {
    testWidgets('renders UI Lab header, scenario chips, and mock canvas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UiLabScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('UI LAB & SANDBOX'), findsOneWidget);
      expect(find.text('Liquid Dev Menu'), findsOneWidget);
      expect(find.text('MOCK APP CONTEXT'), findsOneWidget);
      expect(find.byType(FloatingGhostCapsule), findsOneWidget);
      expect(find.byType(LiquidDevMenuOverlay), findsOneWidget);
    });

    testWidgets('FloatingNavBar includes Lab tab and routes to index 3', (tester) async {
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingNavBar(
              currentIndex: 0,
              onTabSelected: (index) => selectedIndex = index,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(FloatingNavBar.navItems.length, equals(4));
      expect(FloatingNavBar.navItems[3].label, equals('Lab'));

      await tester.tap(find.byKey(const ValueKey('navbar-lab')));
      await tester.pump();
      expect(selectedIndex, equals(3));
    });

    testWidgets('FloatingGhostCapsule bezel dial expands satellites and opens liquid dev menu', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: UiLabScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final quadrantFinder = find.byKey(const Key('radial_edge_quadrant'));
      expect(quadrantFinder, findsOneWidget);

      await tester.tap(quadrantFinder, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));

      final menuSatelliteFinder = find.byKey(const Key('capsule_satellite_menu'));
      expect(menuSatelliteFinder, findsOneWidget);

      await tester.tap(menuSatelliteFinder, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byKey(const Key('active_fluid_docking_hub')), findsOneWidget);

      await tester.tap(find.byKey(const Key('active_fluid_docking_hub')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));
    });
  });
}
