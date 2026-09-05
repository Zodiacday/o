class PreviewConnection {
  static const scheme = 'previewport';
  static const legacyScheme = 'fluttergo';
  static const supportedProtocolVersion = '1';

  final String url;
  final String? projectName;

  const PreviewConnection({required this.url, this.projectName});

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
    return PreviewConnection(
      url: target.toString(),
      projectName: rawName == null || rawName.isEmpty ? null : rawName,
    );
  }

  static bool _isWebUri(Uri uri) {
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
