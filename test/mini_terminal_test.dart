import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    // Tap clear
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    expect(cleared, isTrue);

    // Tap close
    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(closed, isTrue);
  });
}
