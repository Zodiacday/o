import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/models/nearby_preview.dart';

void main() {
  test('parses a valid PreviewPort Bonjour service into an HTTP preview', () {
    final preview = NearbyPreview.fromService(
      BonsoirService(
        name: 'Sink · PreviewPort',
        type: '_previewport._tcp',
        hostAddresses: const ['192.168.0.25'],
        port: 8082,
        attributes: const {
          'v': '1',
          'name': 'Sink',
          'sid': 'session-123',
          'ctrl': 'ws://192.168.0.25:4321/events?token=abc',
        },
      ),
    );

    expect(preview, isNotNull);
    expect(preview!.id, 'session-123');
    expect(preview.projectName, 'Sink');
    expect(preview.url, 'http://192.168.0.25:8082/');
    expect(preview.controlUrl, 'ws://192.168.0.25:4321/events?token=abc');
    expect(preview.displayEndpoint, '192.168.0.25:8082');
  });

  test('ignores services outside the PreviewPort protocol', () {
    final preview = NearbyPreview.fromService(
      BonsoirService(
        name: 'Other service',
        type: '_http._tcp',
        hostAddresses: const ['192.168.0.25'],
        port: 8082,
        attributes: const {'v': '1', 'name': 'Other'},
      ),
    );

    expect(preview, isNull);
  });
}
