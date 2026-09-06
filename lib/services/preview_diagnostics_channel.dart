import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/preview_diagnostic.dart';

typedef PreviewDiagnosticHandler = void Function(PreviewDiagnostic diagnostic);
typedef PreviewHealthyHandler = void Function();

/// Optional diagnostics transport paired with one PreviewPort CLI session.
/// Connection failures are deliberately silent because the preview itself can
/// still be opened from an old QR code, a manual URL, or a raw web URL.
class PreviewDiagnosticsChannel {
  final String? controlUrl;
  final PreviewDiagnosticHandler onDiagnostic;
  final PreviewHealthyHandler onHealthy;

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  bool _disposed = false;

  PreviewDiagnosticsChannel({
    required this.controlUrl,
    required this.onDiagnostic,
    required this.onHealthy,
  });

  Future<void> connect() async {
    if (_disposed || _channel != null || !_isValidControlUrl(controlUrl)) {
      return;
    }

    try {
      final channel = WebSocketChannel.connect(Uri.parse(controlUrl!));
      _channel = channel;
      await channel.ready;
      if (_disposed) return;
      _subscription = channel.stream.listen(
        _handleMessage,
        onError: (_) {},
        onDone: () {},
        cancelOnError: false,
      );
    } catch (_) {
      await _closeChannel();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _subscription?.cancel();
    _subscription = null;
    await _closeChannel();
  }

  void _handleMessage(Object? value) {
    if (_disposed) return;

    Object? decoded = value;
    if (value is String) {
      try {
        decoded = jsonDecode(value);
      } catch (_) {
        return;
      }
    }

    final diagnostic = PreviewDiagnostic.fromJson(decoded);
    if (diagnostic != null) {
      onDiagnostic(diagnostic);
      return;
    }

    if (decoded is Map &&
        decoded['type'] == 'healthy' &&
        decoded['stage'] is String) {
      onHealthy();
    }
  }

  Future<void> _closeChannel() async {
    final channel = _channel;
    _channel = null;
    if (channel == null) return;
    try {
      await channel.sink.close();
    } catch (_) {}
  }

  static bool _isValidControlUrl(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'ws' || uri.scheme == 'wss') &&
        uri.host.isNotEmpty &&
        (uri.queryParameters['token']?.isNotEmpty ?? false);
  }
}
