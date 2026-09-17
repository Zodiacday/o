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

  testWidgets('seed tap directly opens centered dev menu card', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: UiLabScreen()));
    await tester.pump();
    expect(find.byKey(const Key('liquid_menu_title')), findsNothing);

    await tester.tap(find.byKey(const Key('liquid_sidebar_seed')));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byKey(const Key('liquid_menu_card_lens')), findsOneWidget);
    expect(find.byKey(const Key('liquid_menu_title')), findsOneWidget);
    expect(find.text('HOT RELOAD'), findsOneWidget);
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
    'centered dev menu card renders all action items and closes via close button',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const MaterialApp(home: UiLabScreen()));
      await tester.pump();

      // Open centered menu
      await tester.tap(find.byKey(const Key('liquid_sidebar_seed')));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byKey(const Key('liquid_menu_title')), findsOneWidget);
      expect(find.text('HOT RELOAD'), findsOneWidget);
      expect(find.text('RESTART'), findsOneWidget);
      expect(find.text('VIEWPORT'), findsOneWidget);
      expect(find.text('TERMINAL'), findsOneWidget);
      expect(find.byKey(const Key('liquid_menu_close_btn')), findsOneWidget);

      // Tap close button to dismiss
      await tester.tap(find.byKey(const Key('liquid_menu_close_btn')));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byKey(const Key('liquid_menu_title')), findsNothing);
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

      // Open centered menu while offline
      await tester.tap(find.byKey(const Key('liquid_sidebar_seed')));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
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
  });

  testWidgets('hot reload action inside menu triggers hot reload callback', (
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

    // Open menu
    await tester.tap(find.byKey(const Key('liquid_sidebar_seed')));
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('HOT RELOAD'), findsOneWidget);
    await tester.tap(find.text('HOT RELOAD'));
    await tester.pump();

    expect(reloaded, isTrue);
  });
}
