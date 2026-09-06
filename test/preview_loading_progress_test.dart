import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/theme/app_theme.dart';
import 'package:previewport/widgets/preview_loading_progress.dart';

void main() {
  testWidgets('shows a green animated loading meter beneath the percentage', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: AppTheme.background,
          body: Center(child: PreviewLoadingProgress(progress: 42)),
        ),
      ),
    );

    expect(find.text('Preparing preview'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.text('Loading preview…'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('preview-loading-progress')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('preview-loading-fill')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    final fill = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('preview-loading-fill')),
    );
    expect((fill.decoration as BoxDecoration).color, AppTheme.statusGreen);
  });

  testWidgets('uses a connecting state before progress begins', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PreviewLoadingProgress(progress: 0)),
      ),
    );

    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Connecting…'), findsOneWidget);
  });
}
