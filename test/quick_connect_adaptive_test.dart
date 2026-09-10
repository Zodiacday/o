import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
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

  testWidgets('QuickConnectTab auto-adapts to history ports (Angular 4200 and Metro 8081)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final history = [
      SessionItem(
        id: '1',
        url: 'http://192.168.1.100:4200',
        title: 'Customer Angular App',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      SessionItem(
        id: '2',
        url: 'http://192.168.1.100:8081',
        title: 'React Native Metro',
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickConnectTab(
            history: history,
            nearbyPreviews: const [],
            onLaunchApp: (_, {title, controlUrl}) {},
            onOpenHistory: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Mode should be AUTO
    expect(find.text('AUTO'), findsOneWidget);

    // Reachability beacon should display REACHABLE
    expect(find.text('REACHABLE'), findsOneWidget);

    // Edit Slots button should be visible in header
    expect(find.text('Edit Slots'), findsOneWidget);

    // Ports 8081 and 4200 should be auto-detected with their framework signatures
    expect(find.text(':8081'), findsOneWidget);
    expect(find.text('React Native'), findsOneWidget);
    expect(find.text(':4200'), findsOneWidget);
    expect(find.text('Angular'), findsOneWidget);

    // Remaining slots backfilled from defaults (5173, 3000)
    expect(find.text(':5173'), findsOneWidget);
    expect(find.text('Vite / Astro'), findsOneWidget);
    expect(find.text(':3000'), findsOneWidget);
    expect(find.text('Next.js'), findsOneWidget);
  });

  testWidgets('QuickConnectTab loads pinned presets from SharedPreferences and displays PINNED', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final customPresets = [
      {
        'port': 9090,
        'framework': 'Go Gin Microservice',
        'description': 'Backend API',
        'isHttps': false,
        'isCustom': true,
      },
      {
        'port': 5000,
        'framework': 'Flask AI Engine',
        'description': 'Python Web API',
        'isHttps': true,
        'isCustom': true,
      },
      {
        'port': 3000,
        'framework': 'Next.js',
        'description': 'React, Remix, Node',
        'isHttps': false,
        'isCustom': true,
      },
      {
        'port': 8080,
        'framework': 'Spring Boot',
        'description': 'Local Service',
        'isHttps': false,
        'isCustom': true,
      },
    ];

    SharedPreferences.setMockInitialValues({
      'quick_connect_target_host': '192.168.1.100',
      'quick_connect_custom_presets_v1': jsonEncode(customPresets),
    });

    String? launchedUrl;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickConnectTab(
            history: const [],
            nearbyPreviews: const [],
            onLaunchApp: (url, {title, controlUrl}) {
              launchedUrl = url;
            },
            onOpenHistory: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Mode should be PINNED
    expect(find.text('PINNED'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    // Custom ports present
    expect(find.text(':9090'), findsOneWidget);
    expect(find.text('Go Gin Microservice'), findsOneWidget);
    expect(find.text(':5000'), findsOneWidget);
    expect(find.text('Flask AI Engine'), findsOneWidget);

    // SSL badge on port 5000
    expect(find.text('SSL'), findsOneWidget);

    // Tap HTTPS preset :5000
    await tester.tap(find.text(':5000'));
    await tester.pump();
    expect(launchedUrl, 'https://192.168.1.100:5000');

    // Tap Reset to Auto
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    // Mode returns to AUTO and reverts to standard defaults
    expect(find.text('AUTO'), findsOneWidget);
    expect(find.text(':5173'), findsOneWidget);
  });

  testWidgets('Smart de-duplication keeps custom titled sessions and drops generic preset launches', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final history = [
      // 1. Generic auto-launch title (matches preset on port 5173) -> should be filtered
      SessionItem(
        id: 'dup_1',
        url: 'http://192.168.1.100:5173',
        title: 'Vite / Astro (5173)',
        timestamp: DateTime.now(),
      ),
      // 2. Custom named session -> must be kept
      SessionItem(
        id: 'custom_1',
        url: 'http://192.168.1.100:5173',
        title: 'Ecommerce Storefront',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickConnectTab(
            history: history,
            nearbyPreviews: const [],
            onLaunchApp: (_, {title, controlUrl}) {},
            onOpenHistory: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Preset button :5173
    expect(find.text(':5173'), findsOneWidget);

    // Active Prototypes should contain the custom project
    expect(find.text('Ecommerce Storefront'), findsOneWidget);

    // The generic duplicate 'Vite / Astro (5173)' must NOT appear in Active Prototypes
    expect(find.text('Vite / Astro (5173)'), findsNothing);
  });

  testWidgets('Visible edit UI triggers: Edit Slots sheet and card pencil buttons with quick preset chips', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickConnectTab(
            history: const [],
            nearbyPreviews: const [],
            onLaunchApp: (_, {title, controlUrl}) {},
            onOpenHistory: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Header has visible "Edit Slots" button
    expect(find.text('Edit Slots'), findsOneWidget);
    await tester.tap(find.text('Edit Slots'));
    await tester.pumpAndSettle();

    // Bottom sheet opened
    expect(find.text('Customize Matrix Slots'), findsOneWidget);
    expect(find.text(':5173'), findsNWidgets(2)); // in grid + in sheet

    // Close bottom sheet
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // 2. Card has visible pencil icon button
    final pencilIcons = find.byIcon(PhosphorIconsRegular.pencilSimple);
    // At least 4 pencil icons for the 4 cards (+ 1 for Change IP)
    expect(pencilIcons, findsAtLeastNWidgets(5));

    // Tap pencil on first card (index 1 in finder, since index 0 is Change IP)
    await tester.tap(pencilIcons.at(1));
    await tester.pumpAndSettle();

    // Configuration modal opened
    expect(find.text('Slot 1 Configuration'), findsOneWidget);
    expect(find.text('QUICK POPULAR PRESETS'), findsOneWidget);
    expect(find.text(':4200 Angular'), findsOneWidget);

    // Tap quick preset chip ':4200 Angular'
    await tester.tap(find.text(':4200 Angular'));
    await tester.pump();

    // Tap Save & Pin
    await tester.tap(find.text('Save & Pin'));
    await tester.pumpAndSettle();

    // Mode is now PINNED and slot 1 is :4200 Angular!
    expect(find.text('PINNED'), findsOneWidget);
    expect(find.text(':4200'), findsOneWidget);
    expect(find.text('Angular'), findsOneWidget);
  });
}
