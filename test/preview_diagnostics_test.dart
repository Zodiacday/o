import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/models/preview_diagnostic.dart';
import 'package:previewport/services/preview_diagnostics_channel.dart';
import 'package:previewport/theme/app_theme.dart';
import 'package:previewport/widgets/preview_error_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PreviewDiagnostic ignores malformed events and formats details', () {
    expect(PreviewDiagnostic.fromJson(null), isNull);
    expect(
      PreviewDiagnostic.fromJson({'type': 'healthy', 'stage': 'reloaded'}),
      isNull,
    );

    final diagnostic = PreviewDiagnostic.fromJson({
      'type': 'diagnostic',
      'stage': 'hot_reload',
      'message': 'Undefined name',
      'file': 'lib/main.dart',
      'line': 8,
      'column': 4,
      'codeFrame': '8 │ return count;',
    });

    expect(diagnostic, isNotNull);
    expect(diagnostic!.location, 'lib/main.dart:8:4');
    expect(diagnostic.stageLabel, 'Hot reload');
    expect(diagnostic.details, contains('lib/main.dart:8:4'));
    expect(diagnostic.details, contains('return count'));
  });

  testWidgets('PreviewErrorSheet renders details and action callbacks', (
    tester,
  ) async {
    var retries = 0;
    var copies = 0;
    var dismissals = 0;
    const diagnostic = PreviewDiagnostic(
      stage: 'hot_reload',
      message: 'Compilation failed',
      file: 'lib/home.dart',
      line: 142,
      column: 18,
      codeFrame: '> 142 │ return broken;',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: PreviewErrorSheet(
            diagnostic: diagnostic,
            onRetry: () => retries++,
            onCopyDetails: () => copies++,
            onDismiss: () => dismissals++,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Preview failed'), findsOneWidget);
    expect(find.text('Hot reload'), findsOneWidget);
    expect(find.text('Compilation failed'), findsOneWidget);
    expect(find.text('lib/home.dart:142:18'), findsOneWidget);
    expect(find.text('> 142 │ return broken;'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.tap(find.text('Copy details'));
    await tester.tap(find.text('Dismiss'));
    expect(retries, 1);
    expect(copies, 1);
    expect(dismissals, 1);
  });

  test(
    'diagnostics channel ignores malformed events and handles recovery',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        socket
          ..add('not json')
          ..add(jsonEncode({'type': 'diagnostic', 'stage': 'hot_reload'}))
          ..add(
            jsonEncode({
              'type': 'diagnostic',
              'stage': 'hot_reload',
              'message': 'Compilation failed',
            }),
          )
          ..add(jsonEncode({'type': 'healthy', 'stage': 'reloaded'}));
      });

      final diagnostics = <PreviewDiagnostic>[];
      var healthy = 0;
      final channel = PreviewDiagnosticsChannel(
        controlUrl: 'ws://127.0.0.1:${server.port}/events?token=test-token',
        onDiagnostic: diagnostics.add,
        onHealthy: () => healthy++,
      );
      await channel.connect();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await channel.dispose();

      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.message, 'Compilation failed');
      expect(healthy, 1);
    },
  );
}
