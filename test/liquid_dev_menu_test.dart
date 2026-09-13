import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/screens/app_viewer_screen.dart';
import 'package:previewport/widgets/floating_ghost_capsule.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Liquid Dev Menu & Capsule Spatial Alignment', () {
    test('FloatingGhostCapsule.calculateCenterY produces consistent bounds across screen sizes', () {
      final yTop = FloatingGhostCapsule.calculateCenterY(
        screenH: 844.0,
        topInset: 47.0,
        bottomInset: 34.0,
        dy: 0.0,
      );

      final yCenter = FloatingGhostCapsule.calculateCenterY(
        screenH: 844.0,
        topInset: 47.0,
        bottomInset: 34.0,
        dy: 0.5,
      );

      final yBottom = FloatingGhostCapsule.calculateCenterY(
        screenH: 844.0,
        topInset: 47.0,
        bottomInset: 34.0,
        dy: 1.0,
      );

      expect(yTop, equals(155.0));
      expect(yCenter, equals(428.5));
      expect(yBottom, equals(702.0));
      expect(yTop < yCenter, isTrue);
      expect(yCenter < yBottom, isTrue);
    });

    test('ResponsiveFluidPathBuilder generates smooth closed path connected to menu satellite circle', () {
      const size = Size(390.0, 844.0);
      const anchorY = 428.5;

      final satCenter = ResponsiveFluidPathBuilder.getMenuSatelliteCenter(
        size: size,
        anchorY: anchorY,
        isRightSide: true,
      );

      final path = ResponsiveFluidPathBuilder.buildPath(
        size: size,
        anchorY: anchorY,
        isRightSide: true,
      );

      final bounds = path.getBounds();
      expect(bounds.width, greaterThan(250.0));
      expect(bounds.height, greaterThan(400.0));
      // Outer bound encompasses the satellite puck
      expect(bounds.right, closeTo(satCenter.dx + ResponsiveFluidPathBuilder.satelliteRadius, 1.0));

      // Path contains points inside body and the satellite puck center
      final bodyRect = ResponsiveFluidPathBuilder.getBodyRect(
        size: size,
        anchorY: anchorY,
        isRightSide: true,
      );
      expect(path.contains(bodyRect.center), isTrue);
      expect(path.contains(satCenter), isTrue); // Inside the small circle of the menu

      // Does not contain distant corner points
      expect(path.contains(const Offset(10.0, 10.0)), isFalse);
    });

    test('ResponsiveFluidPathBuilder mirrors symmetrically when docked on left bezel', () {
      const size = Size(390.0, 844.0);
      const anchorY = 428.5;

      final satCenterLeft = ResponsiveFluidPathBuilder.getMenuSatelliteCenter(
        size: size,
        anchorY: anchorY,
        isRightSide: false,
      );

      final pathLeft = ResponsiveFluidPathBuilder.buildPath(
        size: size,
        anchorY: anchorY,
        isRightSide: false,
      );

      final bounds = pathLeft.getBounds();
      // Outer bound encompasses the left satellite puck
      expect(bounds.left, closeTo(satCenterLeft.dx - ResponsiveFluidPathBuilder.satelliteRadius, 1.0));

      final bodyRect = ResponsiveFluidPathBuilder.getBodyRect(
        size: size,
        anchorY: anchorY,
        isRightSide: false,
      );
      expect(pathLeft.contains(bodyRect.center), isTrue);
      expect(pathLeft.contains(satCenterLeft), isTrue); // Inside the small circle of the menu
      expect(pathLeft.contains(const Offset(380.0, 10.0)), isFalse);
    });

    test('ResponsiveFluidPathBuilder handles extreme top and bottom anchor positions gracefully', () {
      const size = Size(390.0, 844.0);

      // Extreme top
      final pathTop = ResponsiveFluidPathBuilder.buildPath(
        size: size,
        anchorY: 50.0,
        isRightSide: true,
      );
      expect(pathTop.getBounds().isEmpty, isFalse);

      // Extreme bottom
      final pathBottom = ResponsiveFluidPathBuilder.buildPath(
        size: size,
        anchorY: 800.0,
        isRightSide: true,
      );
      expect(pathBottom.getBounds().isEmpty, isFalse);
    });

    test('ResponsiveFluidMenuPainter paints without throwing Shader/Gradient ArgumentErrors', () {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(390.0, 844.0);

      final painterRight = ResponsiveFluidMenuPainter(
        anchorY: 420.0,
        isRightSide: true,
      );
      expect(() => painterRight.paint(canvas, size), returnsNormally);

      final painterLeft = ResponsiveFluidMenuPainter(
        anchorY: 420.0,
        isRightSide: false,
      );
      expect(() => painterLeft.paint(canvas, size), returnsNormally);

      final bodyRect = ResponsiveFluidPathBuilder.getBodyRect(
        size: size,
        anchorY: 420.0,
        isRightSide: true,
      );
      final blobPainter = AmbientLiquidBlobsPainter(
        progress: 0.45,
        bodyRect: bodyRect,
      );
      expect(() => blobPainter.paint(canvas, size), returnsNormally);
    });
  });
}

