import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/widgets/floating_ghost_capsule.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FloatingGhostCapsule 25% radial bezel expands satellites on tap and executes actions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var reloadCount = 0;
    var menuOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FloatingGhostCapsule(
                onHotReload: () => reloadCount++,
                onOpenMenu: () => menuOpened = true,
                isCliConnected: true,
              ),
            ],
          ),
        ),
      ),
    );

    final quadrantFinder = find.byKey(const Key('radial_edge_quadrant'));
    expect(quadrantFinder, findsOneWidget);

    // Initially collapsed: satellites should not be present
    expect(find.byKey(const Key('capsule_satellite_reload')), findsNothing);
    expect(find.byKey(const Key('capsule_satellite_menu')), findsNothing);

    // 1. Tap the 25% quadrant to expand satellites
    await tester.tap(quadrantFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // complete bloom animation

    expect(find.byKey(const Key('capsule_satellite_reload')), findsOneWidget);
    expect(find.byKey(const Key('capsule_satellite_menu')), findsOneWidget);

    // 2. Tap Hot Reload satellite circle
    await tester.tap(find.byKey(const Key('capsule_satellite_reload')));
    await tester.pump();
    expect(reloadCount, 1);

    await tester.pump(const Duration(milliseconds: 300)); // complete collapse animation

    // Satellites should be retracted after action
    expect(find.byKey(const Key('capsule_satellite_reload')), findsNothing);

    // 3. Re-expand and tap Menu satellite circle
    await tester.tap(quadrantFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('capsule_satellite_menu')), findsOneWidget);

    await tester.tap(find.byKey(const Key('capsule_satellite_menu')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // complete collapse
    expect(menuOpened, isTrue);

    // 4. Long press on quadrant also opens menu directly
    menuOpened = false;
    await tester.longPress(quadrantFinder);
    await tester.pump();
    expect(menuOpened, isTrue);
  });
}
