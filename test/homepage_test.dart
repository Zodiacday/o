import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:previewport/models/session_item.dart';
import 'package:previewport/models/nearby_preview.dart';
import 'package:previewport/services/network_status_service.dart';
import 'package:previewport/screens/tabs/scans_tab.dart';
import 'package:previewport/widgets/hero_scan_card.dart';
import 'package:previewport/widgets/network_status_pill.dart';

class _FakeNetworkStatusService extends NetworkStatusService {
  final NetworkState state;

  _FakeNetworkStatusService([this.state = NetworkState.wifiReady]);

  @override
  Future<NetworkState> getCurrentState() async => state;

  @override
  Stream<NetworkState> get onNetworkStateChanged => const Stream.empty();
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(useMaterial3: true),
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('hero exposes the simple scan-first connection flow', (
    tester,
  ) async {
    var scanCount = 0;
    var pasteCount = 0;
    var enterCount = 0;
    var copyCount = 0;

    await tester.pumpWidget(
      _app(
        HeroScanCard(
          onTap: () => scanCount++,
          onPasteUrl: () => pasteCount++,
          onEnterUrl: () => enterCount++,
          onCopyCommand: () => copyCount++,
          networkService: _FakeNetworkStatusService(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Connect to a Flutter preview'), findsOneWidget);
    expect(find.text('Scan the QR code from your terminal.'), findsNothing);
    expect(find.text('Tap to scan QR code'), findsOneWidget);
    expect(find.text('Ready to scan'), findsNothing);
    expect(find.text('Scan preview'), findsNothing);
    expect(find.text('Paste URL'), findsOneWidget);
    expect(find.text('Enter URL'), findsOneWidget);

    await tester.tap(find.text('Tap to scan QR code'));
    await tester.tap(find.text('Paste URL'));
    await tester.tap(find.text('Enter URL'));
    await tester.tap(find.byKey(const Key('copy-cli-command')));

    await tester.tap(find.byTooltip('Connection information'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('How PreviewPort connects'), findsOneWidget);
    expect(find.text('pp start'), findsOneWidget);

    expect(scanCount, 1);
    expect(pasteCount, 1);
    expect(enterCount, 1);
    expect(copyCount, 1);
  });

  testWidgets('busy scanner state prevents duplicate scans', (tester) async {
    var scanCount = 0;

    await tester.pumpWidget(
      _app(
        HeroScanCard(
          onTap: () => scanCount++,
          onPasteUrl: () {},
          onEnterUrl: () {},
          onCopyCommand: () {},
          isBusy: true,
          networkService: _FakeNetworkStatusService(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Opening scanner…'), findsOneWidget);
    expect(find.text('Tap to scan QR code'), findsNothing);
    expect(find.text('Ready to scan'), findsNothing);
    expect(find.text('Scan preview'), findsNothing);
    expect(find.text('Opening scanner…'), findsWidgets);
    expect(scanCount, 0);
  });

  testWidgets('empty recent previews uses the actionable copy', (tester) async {
    await tester.pumpWidget(
      _app(
        ScansTab(
          history: const [],
          isLoading: false,
          onOpenScanner: () {},
          onPasteUrl: () {},
          onEnterUrl: () {},
          onCopyCommand: () {},
          onLaunchApp: (url, {title, controlUrl}) {},
          onLongPressItem: (_) {},
          networkService: _FakeNetworkStatusService(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Recent previews'), findsOneWidget);
    expect(find.text('No previews yet'), findsOneWidget);
    expect(find.text('Run pp start to begin.'), findsNothing);
    expect(find.text(r'$ previewport'), findsNothing);
  });

  testWidgets('recent preview row launches its original URL', (tester) async {
    const url = 'http://192.168.1.20:8090/';
    var launchedUrl = '';

    await tester.pumpWidget(
      _app(
        ScansTab(
          history: [
            SessionItem(
              id: 'one',
              url: url,
              title: 'Sink',
              timestamp: DateTime.now(),
            ),
          ],
          isLoading: false,
          onOpenScanner: () {},
          onPasteUrl: () {},
          onEnterUrl: () {},
          onCopyCommand: () {},
          onLaunchApp: (value, {title, controlUrl}) => launchedUrl = value,
          onLongPressItem: (_) {},
          networkService: _FakeNetworkStatusService(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Sink'), findsOneWidget);
    expect(find.text('192.168.1.20:8090 · Just now'), findsOneWidget);

    await tester.tap(find.text('Sink'));
    expect(launchedUrl, url);
  });

  testWidgets('nearby preview appears above recent previews and opens on tap', (
    tester,
  ) async {
    const url = 'http://192.168.0.25:8082/';
    var opened = '';

    await tester.pumpWidget(
      _app(
        ScansTab(
          history: const [],
          isLoading: false,
          onOpenScanner: () {},
          onPasteUrl: () {},
          onEnterUrl: () {},
          onCopyCommand: () {},
          onLaunchApp: (value, {title, controlUrl}) {},
          onLongPressItem: (_) {},
          nearbyPreviews: const [
            NearbyPreview(
              id: 'nearby-1',
              projectName: 'Sink',
              url: url,
              host: '192.168.0.25',
              port: 8082,
            ),
          ],
          onOpenNearbyPreview: (preview) => opened = preview.url,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('LIVE WORKSTATION SENSED'), findsOneWidget);
    expect(find.text('192.168.0.25:8082 · Ready on Wi-Fi'), findsOneWidget);
    expect(find.text('Recent previews'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('LIVE WORKSTATION SENSED')).dy,
      lessThan(tester.getTopLeft(find.text('Recent previews')).dy),
    );

    await tester.tap(find.text('Tap to Resume Preview'));
    expect(opened, url);
  });

  testWidgets('network status uses quiet contextual labels', (tester) async {
    const labels = {
      NetworkState.wifiReady: 'Same Wi-Fi usually works best',
      NetworkState.cellularHotspot: 'Cellular connection',
      NetworkState.offline: 'Offline — connect to a network',
      NetworkState.unknown: 'Checking network…',
    };

    for (final entry in labels.entries) {
      await tester.pumpWidget(
        _app(
          NetworkStatusPill(
            key: ValueKey(entry.key),
            service: _FakeNetworkStatusService(entry.key),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(entry.value), findsOneWidget);
    }
  });
}
