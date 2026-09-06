import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/screens/licenses_screen.dart';

void main() {
  testWidgets('licenses page stays readable on a compact phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(472, 972);
    tester.view.devicePixelRatio = 1;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: const LicensesScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Open-source licenses'), findsOneWidget);
    expect(find.text('14 libraries'), findsOneWidget);
    expect(find.text('flutter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
