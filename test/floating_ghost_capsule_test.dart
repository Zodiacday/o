import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/widgets/floating_ghost_capsule.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FloatingGhostCapsule triggers onHotReload on tap and onOpenMenu on long press', (tester) async {
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

    expect(find.text('Reload'), findsOneWidget);

    // Tap triggers hot reload
    await tester.tap(find.text('Reload'));
    await tester.pump();
    expect(reloadCount, 1);

    // Long press triggers menu
    await tester.longPress(find.text('Reloading...'));
    await tester.pump();
    expect(menuOpened, isTrue);
  });
}
