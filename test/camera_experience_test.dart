import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:previewport/models/camera_capture_result.dart';
import 'package:previewport/models/preview_connection.dart';
import 'package:previewport/screens/tabs/scans_tab.dart';
import 'package:previewport/theme/app_theme.dart';
import 'package:previewport/widgets/camera_mode_selector.dart';
import 'package:previewport/widgets/camera_scanner_modal.dart';

Widget _app(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(useMaterial3: true),
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('camera sheet uses 64 percent height and starts in Scan mode', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(const CameraScannerModal(cameraEnabled: false)),
    );
    await tester.pump();

    final sheetFinder = find.byKey(const ValueKey('previewport-camera-sheet'));
    final sheet = tester.getSize(sheetFinder);
    final availableHeight = MediaQuery.sizeOf(
      tester.element(sheetFinder),
    ).height;
    expect(sheet.height, closeTo(availableHeight * 0.64, 0.5));
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Photo'), findsOneWidget);
    expect(find.text('Align the QR code inside the frame'), findsNothing);

    final scanButton = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text('Scan'),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect((scanButton.decoration! as BoxDecoration).color, AppTheme.cyan);
  });

  testWidgets('camera mode selector changes from Scan to Photo', (
    tester,
  ) async {
    var selected = CameraMode.scan;

    await tester.pumpWidget(
      _app(
        CameraModeSelector(
          value: selected,
          onChanged: (mode) => selected = mode,
        ),
      ),
    );

    await tester.tap(find.text('Photo'));
    expect(selected, CameraMode.photo);
  });

  test('camera result types preserve the QR connection', () {
    const connection = PreviewConnection(
      url: 'http://192.168.1.20:8080',
      projectName: 'Sink',
    );
    final result = QrCameraCapture(connection);

    expect(result.connection, same(connection));
  });

  test('camera result types preserve the selected photo', () {
    final result = PhotoCameraCapture(XFile('preview-photo.jpg'));

    expect(result.file.path, 'preview-photo.jpg');
  });

  testWidgets('home shows a captured photo preview without persistence', (
    tester,
  ) async {
    final imageBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );

    await tester.pumpWidget(
      _app(
        ScansTab(
          history: const [],
          isLoading: false,
          onOpenScanner: () {},
          onPasteUrl: () {},
          onEnterUrl: () {},
          onCopyCommand: () {},
          onLaunchApp: (url, {title}) {},
          onLongPressItem: (_) {},
          capturedPhotoBytes: imageBytes,
          onDismissCapturedPhoto: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('Photo captured'), findsOneWidget);
    expect(find.text('Ready for your next action'), findsOneWidget);
    expect(find.byTooltip('Remove captured photo'), findsOneWidget);
  });
}
