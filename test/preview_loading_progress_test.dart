import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/theme/app_theme.dart';
import 'package:previewport/widgets/preview_loading_progress.dart';

Widget _testHost({required int progress, String? projectName}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      backgroundColor: AppTheme.background,
      body: PreviewLoadingProgress(
        progress: progress,
        projectName: projectName,
      ),
    ),
  );
}

void main() {
  testWidgets('renders the focused circular loading experience', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHost(progress: 42, projectName: 'Daily Tasks'),
    );

    expect(find.text('PreviewPort'), findsOneWidget);
    expect(find.text('Loading Flutter preview'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.text('Daily Tasks'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('preview-loading-progress')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('preview-loading-ring')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('clamps progress and uses the fallback project name', (
    tester,
  ) async {
    await tester.pumpWidget(_testHost(progress: 140));
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Flutter preview'), findsOneWidget);

    await tester.pumpWidget(_testHost(progress: -20));
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('animates progress without throwing', (tester) async {
    await tester.pumpWidget(_testHost(progress: 0));
    await tester.pumpWidget(_testHost(progress: 64, projectName: 'Sink'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('64%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exposes an accessible live progress label', (tester) async {
    await tester.pumpWidget(_testHost(progress: 64));

    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('preview-loading-progress')),
    );
    expect(semantics.label, contains('Loading Flutter preview 64 percent'));
  });
}
