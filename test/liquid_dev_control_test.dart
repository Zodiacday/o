import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/widgets/native_glass_morph_lab.dart';
import 'package:previewport/widgets/liquid_sidebar_seed.dart';

void main() {
  testWidgets('liquid seed morphs to menu and controller dismisses it', (
    tester,
  ) async {
    final controller = LiquidDevControlController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NativeGlassMorphLab(
            controller: controller,
            onHotReload: () {},
            onRestart: () {},
            onOpenViewportSwitcher: () {},
            onOpenTerminal: () {},
            onClearCache: () {},
            onExit: () {},
            selectedDeviceName: 'iPhone',
            selectedDeviceIcon: Icons.phone_iphone,
            terminalLogCount: 2,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('native_glass_seed')), findsOneWidget);
    await controller.openMenu();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('liquid_menu_title')), findsOneWidget);

    await controller.dismiss();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('native_glass_seed')), findsOneWidget);
  });

  testWidgets(
    'LiquidSidebarSeed responds to LiquidDevControlController openMenu and dismiss',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = LiquidDevControlController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                LiquidSidebarSeed(
                  controller: controller,
                  onHotReload: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('liquid_sidebar_seed')), findsOneWidget);
      expect(find.byKey(const Key('liquid_menu_title')), findsNothing);

      await controller.openMenu();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const Key('liquid_menu_title')), findsOneWidget);

      await controller.dismiss();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const Key('liquid_menu_title')), findsNothing);
    },
  );

  testWidgets(
    'LiquidSidebarSeed menu card actions (Hot Reload, Restart, Viewport, Terminal, Clear Cache, Exit, Close) execute callbacks',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);

      bool reloaded = false;
      bool restarted = false;
      bool viewportOpened = false;
      bool terminalOpened = false;
      bool cacheCleared = false;
      bool exited = false;

      final controller = LiquidDevControlController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                LiquidSidebarSeed(
                  controller: controller,
                  title: 'Test App',
                  isCliConnected: true,
                  terminalLogCount: 5,
                  onHotReload: () => reloaded = true,
                  onRestart: () => restarted = true,
                  onOpenViewportSwitcher: () => viewportOpened = true,
                  onOpenTerminal: () => terminalOpened = true,
                  onClearCache: () => cacheCleared = true,
                  onExit: () => exited = true,
                ),
              ],
            ),
          ),
        ),
      );

      // Programmatically open menu card
      await controller.openMenu();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('HOT RELOAD'), findsOneWidget);
      expect(find.text('RESTART'), findsOneWidget);
      expect(find.text('VIEWPORT'), findsOneWidget);
      expect(find.text('TERMINAL'), findsOneWidget);
      expect(find.text('CLEAR CACHE'), findsOneWidget);
      expect(find.text('EXIT'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // terminal log count badge

      // 1. Hot Reload tap
      await tester.tap(find.text('HOT RELOAD'));
      await tester.pump();
      expect(reloaded, isTrue);

      // Re-open menu
      await controller.openMenu();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 2. Restart tap
      await tester.tap(find.text('RESTART'));
      await tester.pump();
      expect(restarted, isTrue);

      // Re-open menu
      await controller.openMenu();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 3. Viewport tap
      await tester.tap(find.text('VIEWPORT'));
      await tester.pump();
      expect(viewportOpened, isTrue);

      // Re-open menu
      await controller.openMenu();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 4. Terminal tap
      await tester.tap(find.text('TERMINAL'));
      await tester.pump();
      expect(terminalOpened, isTrue);

      // Re-open menu
      await controller.openMenu();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 5. Clear Cache tap
      await tester.tap(find.text('CLEAR CACHE'));
      await tester.pump();
      expect(cacheCleared, isTrue);

      // Re-open menu
      await controller.openMenu();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // 6. Exit tap
      await tester.tap(find.text('EXIT'));
      await tester.pump();
      expect(exited, isTrue);

      // Re-open menu and test Close button
      await controller.openMenu();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const Key('liquid_menu_close_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('liquid_menu_close_btn')));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const Key('liquid_menu_title')), findsNothing);
    },
  );
}

