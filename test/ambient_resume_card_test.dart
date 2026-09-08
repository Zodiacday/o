import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/models/nearby_preview.dart';
import 'package:previewport/widgets/ambient_resume_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AmbientResumeCard renders live workstation details and triggers callbacks', (tester) async {
    const preview = NearbyPreview(
      id: 'test_session_123',
      projectName: 'Courier Mobile App',
      url: 'http://192.168.1.100:58300/',
      host: '192.168.1.100',
      port: 58300,
      controlUrl: 'ws://192.168.1.100:58301/events?token=abc',
    );

    var resumed = false;
    var scanned = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmbientResumeCard(
            preview: preview,
            animatePulse: false,
            onResume: () => resumed = true,
            onScanQr: () => scanned = true,
          ),
        ),
      ),
    );

    expect(find.text('LIVE WORKSTATION SENSED'), findsOneWidget);
    expect(find.text('Courier Mobile App'), findsOneWidget);
    expect(find.text('192.168.1.100:58300 · Ready on Wi-Fi'), findsOneWidget);
    expect(find.text('Tap to Resume Preview'), findsOneWidget);

    await tester.tap(find.text('Tap to Resume Preview'));
    await tester.pump();
    expect(resumed, isTrue);

    await tester.tap(find.text('Or scan a different QR code'));
    await tester.pump();
    expect(scanned, isTrue);
  });
}
