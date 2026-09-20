import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/models/session_item.dart';
import 'package:previewport/models/preview_connection.dart';
import 'package:previewport/services/network_status_service.dart';
import 'package:previewport/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SessionItem serializes and deserializes correctly', () {
    final item = SessionItem(
      id: 'test_1',
      url: 'http://192.168.0.25:8081',
      title: 'Sink Flutter',
      timestamp: DateTime(2026, 8, 29, 12, 0),
      isFavorite: true,
    );

    final json = item.toJson();
    final reconstructed = SessionItem.fromJson(json);

    expect(reconstructed.id, equals('test_1'));
    expect(reconstructed.url, equals('http://192.168.0.25:8081'));
    expect(reconstructed.title, equals('Sink Flutter'));
    expect(reconstructed.isFavorite, isTrue);
  });

  test('AppTheme loads dark theme correctly', () {
    final theme = AppTheme.darkTheme;
    expect(theme.brightness, equals(AppTheme.darkTheme.brightness));
    expect(AppTheme.primary, isNotNull);
  });

  test('PreviewConnection parses PreviewPort QR payloads', () {
    final connection = PreviewConnection.tryParse(
      'previewport://connect?v=1&url=http%3A%2F%2F192.168.1.4%3A8080&name=demo_app&control=ws%3A%2F%2F192.168.1.4%3A4321%2Fevents%3Ftoken%3Dabc',
    );

    expect(connection, isNotNull);
    expect(connection!.url, 'http://192.168.1.4:8080');
    expect(connection.projectName, 'demo_app');
    expect(connection.controlUrl, 'ws://192.168.1.4:4321/events?token=abc');
  });

  test('PreviewConnection keeps raw web URLs compatible', () {
    final connection = PreviewConnection.tryParse(
      'https://example.com/preview',
    );

    expect(connection, isNotNull);
    expect(connection!.url, 'https://example.com/preview');
    expect(connection.projectName, isNull);
  });

  test('PreviewConnection keeps legacy Flutter Go payloads compatible', () {
    final connection = PreviewConnection.tryParse(
      'fluttergo://connect?v=1&url=https%3A%2F%2Fexample.com&name=legacy',
    );

    expect(connection?.url, 'https://example.com');
    expect(connection?.projectName, 'legacy');
  });

  test('PreviewConnection rejects unsafe and malformed payloads', () {
    expect(PreviewConnection.tryParse('javascript:alert(1)'), isNull);
    expect(
      PreviewConnection.tryParse(
        'fluttergo://connect?v=2&url=https://example.com',
      ),
      isNull,
    );
    expect(PreviewConnection.tryParse('fluttergo://connect?v=1'), isNull);
    expect(
      PreviewConnection.tryParse(
        'previewport://connect?v=1&url=http%3A%2F%2F192.168.1.4%3A8080&control=ws%3A%2F%2F10.0.0.2%3A4321%2Fevents%3Ftoken%3Dabc',
      )?.controlUrl,
      isNull,
    );
  });

  test('NetworkStatusService maps Wi-Fi and Ethernet to wifiReady', () {
    expect(
      NetworkStatusService.mapConnectivityResults([ConnectivityResult.wifi]),
      equals(NetworkState.wifiReady),
    );
    expect(
      NetworkStatusService.mapConnectivityResults([
        ConnectivityResult.ethernet,
      ]),
      equals(NetworkState.wifiReady),
    );
    expect(
      NetworkStatusService.mapConnectivityResults([
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
      ]),
      equals(NetworkState.wifiReady),
    );
  });

  test('NetworkStatusService maps Cellular to cellularHotspot', () {
    expect(
      NetworkStatusService.mapConnectivityResults([ConnectivityResult.mobile]),
      equals(NetworkState.cellularHotspot),
    );
  });

  test('NetworkStatusService maps offline and empty to offline', () {
    expect(
      NetworkStatusService.mapConnectivityResults([ConnectivityResult.none]),
      equals(NetworkState.offline),
    );
    expect(
      NetworkStatusService.mapConnectivityResults([]),
      equals(NetworkState.offline),
    );
  });
}
