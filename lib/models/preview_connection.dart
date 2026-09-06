class PreviewConnection {
  static const scheme = 'previewport';
  static const legacyScheme = 'fluttergo';
  static const supportedProtocolVersion = '1';

  final String url;
  final String? projectName;
  final String? controlUrl;

  const PreviewConnection({
    required this.url,
    this.projectName,
    this.controlUrl,
  });

  static PreviewConnection? tryParse(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return null;

    final uri = Uri.tryParse(raw);
    if (uri == null) return null;

    if (_isWebUri(uri)) {
      return PreviewConnection(url: uri.toString());
    }

    if ((uri.scheme != scheme && uri.scheme != legacyScheme) ||
        uri.host != 'connect') {
      return null;
    }

    final version = uri.queryParameters['v'];
    if (version != supportedProtocolVersion) return null;

    final target = Uri.tryParse(uri.queryParameters['url'] ?? '');
    if (target == null || !_isWebUri(target)) return null;

    final rawName = uri.queryParameters['name']?.trim();
    final controlUrl = tryParseControlUrl(
      uri.queryParameters['control'],
      expectedHost: target.host,
    );
    return PreviewConnection(
      url: target.toString(),
      projectName: rawName == null || rawName.isEmpty ? null : rawName,
      controlUrl: controlUrl,
    );
  }

  /// Returns a control endpoint only when it is a tokenized WebSocket URL
  /// for the same host as the preview. Old payloads simply return null.
  static String? tryParseControlUrl(String? rawValue, {String? expectedHost}) {
    final raw = rawValue?.trim();
    if (raw == null || raw.isEmpty) return null;

    final uri = Uri.tryParse(raw);
    if (uri == null || (uri.scheme != 'ws' && uri.scheme != 'wss')) {
      return null;
    }
    final token = uri.queryParameters['token'];
    if (uri.host.isEmpty || token == null || token.isEmpty) {
      return null;
    }
    if (expectedHost != null &&
        uri.host.toLowerCase() != expectedHost.toLowerCase()) {
      return null;
    }
    return uri.toString();
  }

  static bool _isWebUri(Uri uri) {
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
