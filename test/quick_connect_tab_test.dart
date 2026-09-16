import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:previewport/models/session_item.dart';
import 'package:previewport/screens/tabs/quick_connect_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'quick_connect_target_host': '192.168.1.100',
    });
  });

  testWidgets('QuickConnectTab renders workstation HUD and port presets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    String? launchedUrl;
    var openedHistory = false;

    final dummyHistory = [
      SessionItem(
        id: 'sess_1',
        url: 'http://192.168.1.100:5173',
        title: 'Vite Dashboard',
        timestamp: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickConnectTab(
            history: dummyHistory,
            nearbyPreviews: const [],
            onLaunchApp: (url, {title, controlUrl}) {
              launchedUrl = url;
            },
            onOpenHistory: () {
              openedHistory = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Check HUD
    expect(find.text('TARGET WORKSTATION'), findsOneWidget);
    expect(find.text('192.168.1.100'), findsOneWidget);
    expect(find.text('UNREACHABLE'), findsOneWidget);

    // Check Dev Framework Matrix: Slot 1 auto-learns 5173, slots 2-4 stay EMPTY
    expect(find.text(':5173'), findsOneWidget);
    expect(find.text('Vite / Astro'), findsOneWidget);
    expect(find.text('EMPTY'), findsNWidgets(3));
    expect(find.text('Assign Port'), findsNWidgets(3));

    // Check Active Prototypes
    expect(find.text('ACTIVE PROTOTYPES TODAY'), findsOneWidget);
    expect(find.text('Vite Dashboard'), findsOneWidget);

    // Tap preset :5173
    await tester.tap(find.text(':5173'));
    await tester.pump();
    expect(launchedUrl, 'http://192.168.1.100:5173');

    // Tap history footer link
    await tester.tap(find.textContaining('Open History in Settings'));
    await tester.pump();
    expect(openedHistory, isTrue);
  });
}
