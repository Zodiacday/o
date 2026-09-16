import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/models/network_request_entry.dart';
import 'package:previewport/widgets/mini_terminal_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MiniTerminalDrawer renders logs and responds to filtering', (tester) async {
    final logs = [
      TerminalLogEntry(id: '1', message: 'App started cleanly', level: 'info', source: 'flutter'),
      TerminalLogEntry(id: '2', message: 'Warning: high memory usage', level: 'warn', source: 'flutter'),
      TerminalLogEntry(id: '3', message: 'Uncaught TypeError on line 42', level: 'error', source: 'web'),
    ];

    var cleared = false;
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiniTerminalDrawer(
            logs: logs,
            onClear: () => cleared = true,
            onClose: () => closed = true,
          ),
        ),
      ),
    );

    expect(find.text('Live Console'), findsOneWidget);
    expect(find.text('App started cleanly'), findsOneWidget);
    expect(find.text('Warning: high memory usage'), findsOneWidget);
    expect(find.text('Uncaught TypeError on line 42'), findsOneWidget);

    // Tap Errors filter
    await tester.tap(find.text('Errors (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Uncaught TypeError on line 42'), findsOneWidget);
    expect(find.text('App started cleanly'), findsNothing);

    // Test real-time search filter
    await tester.tap(find.text('All (3)'));
    await tester.pumpAndSettle();
    expect(find.text('App started cleanly'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'memory');
    await tester.pumpAndSettle();
    expect(find.text('Warning: high memory usage'), findsOneWidget);
    expect(find.text('App started cleanly'), findsNothing);
    expect(find.text('Uncaught TypeError on line 42'), findsNothing);

    // Tap clear
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    expect(cleared, isTrue);

    // Tap close
    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(closed, isTrue);
  });

  testWidgets('MiniTerminalDrawer renders network tab, filters requests, and displays details', (tester) async {
    final requests = [
      NetworkRequestEntry(
        id: '1',
        url: 'http://192.168.1.50:8000/api/v1/user',
        method: 'GET',
        status: 200,
        statusText: 'OK',
        durationMs: 35,
        initiator: 'fetch',
      ),
      NetworkRequestEntry(
        id: '2',
        url: 'http://192.168.1.50:8000/api/v1/login',
        method: 'POST',
        status: 500,
        statusText: 'Internal Error',
        durationMs: 420,
        initiator: 'fetch',
      ),
      NetworkRequestEntry(
        id: '3',
        url: 'http://192.168.1.50:8000/api/v1/large-dataset',
        method: 'GET',
        status: 200,
        statusText: 'OK',
        durationMs: 850,
        initiator: 'xhr',
      ),
    ];

    var clearedNetwork = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiniTerminalDrawer(
            logs: const [],
            networkRequests: requests,
            onClear: () {},
            onClearNetwork: () => clearedNetwork = true,
            onClose: () {},
          ),
        ),
      ),
    );

    // Switch to Network tab
    await tester.tap(find.text('Network'));
    await tester.pumpAndSettle();

    expect(find.text('/api/v1/user'), findsOneWidget);
    expect(find.text('/api/v1/login'), findsOneWidget);
    expect(find.text('/api/v1/large-dataset'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
    expect(find.text('35ms'), findsOneWidget);
    expect(find.text('850ms'), findsOneWidget);

    // Filter by Errors
    await tester.tap(find.text('Errors (1)'));
    await tester.pumpAndSettle();

    expect(find.text('/api/v1/login'), findsOneWidget);
    expect(find.text('/api/v1/user'), findsNothing);

    // Filter by Slow
    await tester.tap(find.text('Slow (1)'));
    await tester.pumpAndSettle();

    expect(find.text('/api/v1/large-dataset'), findsOneWidget);
    expect(find.text('/api/v1/login'), findsNothing);

    // Tap the slow request to open inspection sheet
    await tester.tap(find.text('/api/v1/large-dataset'));
    await tester.pumpAndSettle();

    expect(find.text('Copy as cURL'), findsOneWidget);
    expect(find.text('Request URL'), findsOneWidget);
    expect(find.text('XHR'), findsOneWidget);

    // Tap Copy as cURL
    await tester.tap(find.text('Copy as cURL'));
    await tester.pumpAndSettle();

    // Tap clear network
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    expect(clearedNetwork, isTrue);
  });
}
