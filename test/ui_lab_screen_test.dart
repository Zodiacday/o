import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/screens/ui_lab_screen.dart';
import 'package:previewport/widgets/floating_navbar.dart';
import 'package:previewport/widgets/native_glass_morph_lab.dart';
import 'package:previewport/widgets/liquid_sidebar_seed.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('UI Lab contains only the pure liquid sidebar seed', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: UiLabScreen()));
    await tester.pump();

    expect(find.byType(LiquidSidebarSeed), findsOneWidget);
    expect(find.byKey(const Key('liquid_sidebar_seed_lens')), findsOneWidget);
    expect(find.byKey(const Key('liquid_reload_connector')), findsOneWidget);
    expect(find.byKey(const Key('liquid_menu_connector')), findsOneWidget);
    expect(find.byType(NativeGlassMorphLab), findsNothing);
  });

  testWidgets('liquid sidebar seed can move vertically', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: UiLabScreen()));
    await tester.pump();
    final before = tester.getTopLeft(
      find.byKey(const Key('liquid_sidebar_seed_position')),
    );
    await tester.drag(
      find.byKey(const Key('liquid_sidebar_seed')),
      const Offset(0, -100),
    );
    await tester.pump();
    final after = tester.getTopLeft(
      find.byKey(const Key('liquid_sidebar_seed_position')),
    );

    expect(after.dy, lessThan(before.dy));
  });

  testWidgets('seed releases reload and menu glass circles', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: UiLabScreen()));
    await tester.pump();
    expect(find.byKey(const Key('liquid_reload_circle')), findsNothing);
    expect(find.byKey(const Key('liquid_menu_circle')), findsNothing);

    await tester.tap(find.byKey(const Key('liquid_sidebar_seed')));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byKey(const Key('liquid_reservoir_blender')), findsOneWidget);
    expect(find.byKey(const Key('liquid_reload_circle')), findsOneWidget);
    expect(find.byKey(const Key('liquid_menu_circle')), findsOneWidget);
  });

  testWidgets('FloatingNavBar excludes Lab and routes standard destinations', (tester) async {
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

    expect(FloatingNavBar.navItems.length, 3);
    expect(find.byKey(const ValueKey('navbar-lab')), findsNothing);
    expect(find.byKey(const ValueKey('navbar-scanner')), findsOneWidget);
    expect(find.byKey(const ValueKey('navbar-connect')), findsOneWidget);
    expect(find.byKey(const ValueKey('navbar-settings')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('navbar-settings')));
    await tester.pump();
    expect(selectedIndex, 2);
  });

  testWidgets(
    'menu satellite circle morphs into full dev menu card and closes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: UiLabScreen()));
      await tester.pump();

      // Open satellites
      await tester.tap(find.byKey(const Key('liquid_sidebar_seed')));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byKey(const Key('liquid_menu_circle')), findsOneWidget);
      expect(find.byKey(const Key('liquid_menu_title')), findsNothing);

      // Tap menu circle to expand into full menu card
      await tester.tap(find.byKey(const Key('liquid_menu_circle')));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byKey(const Key('liquid_menu_title')), findsOneWidget);
      expect(find.text('HOT RELOAD'), findsOneWidget);
      expect(find.text('RESTART'), findsOneWidget);
      expect(find.text('VIEWPORT'), findsOneWidget);
      expect(find.text('TERMINAL'), findsOneWidget);
      expect(find.byKey(const Key('liquid_menu_close_btn')), findsOneWidget);

      // Tap close button to reverse morph
      await tester.tap(find.byKey(const Key('liquid_menu_close_btn')));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byKey(const Key('liquid_menu_title')), findsNothing);
      expect(find.byKey(const Key('liquid_menu_circle')), findsOneWidget);
    },
  );

  testWidgets(
    'CLI status toggle switches between LIVE (Cyan) and OFFLINE (Amber) modes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: UiLabScreen()));
      await tester.pump();

      // Starts in CLI LIVE (Cyan)
      expect(find.text('CLI LIVE'), findsOneWidget);
      expect(find.text('CLI OFFLINE'), findsNothing);

      // Toggle to OFFLINE (Amber)
      await tester.tap(find.byKey(const Key('ui_lab_cli_toggle')));
      await tester.pump();

      expect(find.text('CLI OFFLINE'), findsOneWidget);
      expect(find.text('CLI LIVE'), findsNothing);

      // Open satellites & menu card while offline
      await tester.tap(find.byKey(const Key('liquid_sidebar_seed')));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(find.byKey(const Key('liquid_menu_circle')));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Hot reload shows OFFLINE badge pill while preserving HOT RELOAD label
      expect(find.text('HOT RELOAD'), findsOneWidget);
      expect(find.text('OFFLINE'), findsOneWidget);
    },
  );

  testWidgets('liquid sidebar seed can dock on left or right bezel and mirror geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: UiLabScreen()));
    await tester.pump();

    // Starts docked on the right bezel
    final initialPos = tester.getTopLeft(
      find.byKey(const Key('liquid_sidebar_seed_position')),
    );
    expect(initialPos.dx, greaterThan(300));

    // Drag to the left edge (< 40% screen width = 156px)
    await tester.drag(
      find.byKey(const Key('liquid_sidebar_seed')),
      const Offset(-300, 0),
    );
    await tester.pump();

    final leftPos = tester.getTopLeft(
      find.byKey(const Key('liquid_sidebar_seed_position')),
    );
    expect(leftPos.dx, equals(12.0)); // _edgeMargin

    // Expand satellites on left side
    await tester.tap(find.byKey(const Key('liquid_sidebar_seed')));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Satellite centers mirror to left side (_circleInset = 88px)
    final reloadPos = tester.getCenter(
      find.byKey(const Key('liquid_reload_circle')),
    );
    expect(reloadPos.dx, equals(88.0));
  });

  testWidgets('hot reload satellite triggers hot reload callback and spin', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    bool reloaded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              LiquidSidebarSeed(
                onHotReload: () => reloaded = true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    // Open satellites
    await tester.tap(find.byKey(const Key('liquid_sidebar_seed')));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byKey(const Key('liquid_reload_circle')), findsOneWidget);
    await tester.tap(find.byKey(const Key('liquid_reload_circle')));
    await tester.pump();

    expect(reloaded, isTrue);
  });
}
