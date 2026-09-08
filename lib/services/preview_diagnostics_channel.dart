import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
  final void Function(String message, String level, String source)? onLog;
  final void Function(bool connected)? onConnectionChanged;
  final VoidCallback? onBugReportAck;

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _subscription;
  bool _disposed = false;
  bool _connected = false;
  Map<String, Object?>? _latestProgress;
  Timer? _reconnectTimer;

  bool get isConnected => _connected;

  void triggerHotReload() {
    if (_disposed || !_connected) return;
    _channel?.sink.add(jsonEncode({'type': 'action', 'action': 'reload'}));
  }

  void triggerHotRestart() {
    if (_disposed || !_connected) return;
    _channel?.sink.add(jsonEncode({'type': 'action', 'action': 'restart'}));
  }

  void sendBugReport({required String base64Image, String? notes, String? device}) {
    if (_disposed || !_connected) return;
    _channel?.sink.add(jsonEncode({
      'type': 'bug_report',
      'image': base64Image,
      'notes': notes,
      'device': device ?? 'iPhone',
    }));
  }

  void reportProgress(int percent, {String state = 'loading'}) {
    if (_disposed) return;
    _latestProgress = {
      'type': 'preview_progress',
      'percent': percent.clamp(0, 100),
      'state': state,
    };
    if (_connected) _channel?.sink.add(jsonEncode(_latestProgress));
  }

  void _reconnect() {
    if (_disposed) return;
    _connected = false;
    onConnectionChanged?.call(false);
    _channel = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), connect);
  }

  PreviewDiagnosticsChannel({
    required this.controlUrl,
    required this.onDiagnostic,
    required this.onHealthy,
    this.onLog,
    this.onConnectionChanged,
    this.onBugReportAck,
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
      _connected = true;
      onConnectionChanged?.call(true);
      if (_latestProgress != null) channel.sink.add(jsonEncode(_latestProgress));
      _subscription = channel.stream.listen(
        _handleMessage,
        onError: (_) {},
        onDone: _reconnect,
        cancelOnError: false,
      );
    } catch (_) {
      await _closeChannel();
      _reconnect();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _reconnectTimer?.cancel();
    _connected = false;
    onConnectionChanged?.call(false);
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
      return;
    }

    if (decoded is Map && decoded['type'] == 'bug_report_ack') {
      onBugReportAck?.call();
      return;
    }

    if (decoded is Map && decoded['type'] == 'log') {
      final message = decoded['message'] as String?;
      final level = decoded['level'] as String? ?? 'info';
      if (message != null && message.trim().isNotEmpty) {
        onLog?.call(message.trim(), level, 'flutter');
      }
      return;
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
