import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/models/network_request_entry.dart';

void main() {
  group('NetworkRequestEntry', () {
    test('instantiates with proper getters and default values', () {
      final req = NetworkRequestEntry(
        id: 'req_123',
        url: 'http://192.168.1.50:8000/api/v1/users?limit=10',
        method: 'GET',
        status: 200,
        statusText: 'OK',
        durationMs: 42,
        initiator: 'fetch',
      );

      expect(req.id, equals('req_123'));
      expect(req.url, equals('http://192.168.1.50:8000/api/v1/users?limit=10'));
      expect(req.method, equals('GET'));
      expect(req.status, equals(200));
      expect(req.statusText, equals('OK'));
      expect(req.durationMs, equals(42));
      expect(req.initiator, equals('fetch'));

      expect(req.isSuccess, isTrue);
      expect(req.isError, isFalse);
      expect(req.isSlow, isFalse);
      expect(req.pathWithQuery, equals('/api/v1/users?limit=10'));
      expect(req.hostWithPort, equals('192.168.1.50:8000'));
      expect(req.toCurl(), equals('curl -X GET "http://192.168.1.50:8000/api/v1/users?limit=10"'));
    });

    test('correctly classifies error, slow, and redirect statuses', () {
      final notFound = NetworkRequestEntry(
        id: 'req_404',
        url: 'https://example.com/missing',
        method: 'POST',
        status: 404,
        statusText: 'Not Found',
        durationMs: 120,
      );
      expect(notFound.isClientError, isTrue);
      expect(notFound.isError, isTrue);
      expect(notFound.isSuccess, isFalse);

      final serverError = NetworkRequestEntry(
        id: 'req_500',
        url: 'https://example.com/crash',
        method: 'GET',
        status: 500,
        statusText: 'Internal Server Error',
        durationMs: 850,
      );
      expect(serverError.isServerError, isTrue);
      expect(serverError.isError, isTrue);
      expect(serverError.isSlow, isTrue);

      final failedNetwork = NetworkRequestEntry(
        id: 'req_err',
        url: 'http://localhost:3000/failed',
        method: 'GET',
        status: 0,
        statusText: 'Network Error',
        durationMs: 15,
      );
      expect(failedNetwork.isError, isTrue);
    });

    test('serializes to and from json accurately', () {
      final now = DateTime.now();
      final entry = NetworkRequestEntry(
        id: 'req_test',
        url: 'http://192.168.1.100:3000/api/login',
        method: 'post',
        status: 201,
        statusText: 'Created',
        durationMs: 110,
        initiator: 'xhr',
        timestamp: now,
      );

      final json = entry.toJson();
      expect(json['id'], equals('req_test'));
      expect(json['method'], equals('POST'));
      expect(json['status'], equals(201));
      expect(json['initiator'], equals('xhr'));

      final reconstructed = NetworkRequestEntry.fromJson(json);
      expect(reconstructed.id, equals(entry.id));
      expect(reconstructed.url, equals(entry.url));
      expect(reconstructed.method, equals('POST'));
      expect(reconstructed.status, equals(201));
      expect(reconstructed.durationMs, equals(110));
      expect(reconstructed.initiator, equals('xhr'));
    });
  });
}
