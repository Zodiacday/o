import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:previewport/models/session_item.dart';
import 'package:previewport/screens/history_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HistoryScreen renders items and allows searching and launching', (
    tester,
  ) async {
    final session1 = SessionItem(
      id: 'sess_1',
      url: 'http://192.168.1.100:5173',
      title: 'Storefront Web',
      timestamp: DateTime.now(),
    );
    final session2 = SessionItem(
      id: 'sess_2',
      url: 'http://192.168.1.100:3000',
      title: 'Admin Dashboard',
      timestamp: DateTime.now(),
    );

    SharedPreferences.setMockInitialValues({
      'flutter_go_history_v2': [
        jsonEncode(session1.toJson()),
        jsonEncode(session2.toJson()),
      ],
    });

    String? launchedUrl;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryScreen(
            onLaunchApp: (url, {title, controlUrl}) {
              launchedUrl = url;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Check title and list
    expect(find.text('Scan History'), findsOneWidget);
    expect(find.text('Storefront Web'), findsOneWidget);
    expect(find.text('Admin Dashboard'), findsOneWidget);

    // Filter using search
    await tester.enterText(find.byType(TextField), 'Admin');
    await tester.pumpAndSettle();

    expect(find.text('Storefront Web'), findsNothing);
    expect(find.text('Admin Dashboard'), findsOneWidget);

    // Tap on Admin Dashboard to launch
    await tester.tap(find.text('Admin Dashboard'));
    await tester.pump();
    expect(launchedUrl, 'http://192.168.1.100:3000');
  });
}
