/// Represents an HTTP network request captured by Previewport's in-app network inspector.
class NetworkRequestEntry {
  final String id;
  final String url;
  final String method;
  final int status;
  final String statusText;
  final int durationMs;
  final String initiator; // 'fetch' | 'xhr'
  final DateTime timestamp;

  NetworkRequestEntry({
    required this.id,
    required this.url,
    required String method,
    required this.status,
    this.statusText = '',
    required this.durationMs,
    this.initiator = 'fetch',
    DateTime? timestamp,
  })  : method = method.toUpperCase(),
        timestamp = timestamp ?? DateTime.now();

  bool get isSuccess => status >= 200 && status < 300;
  bool get isRedirect => status >= 300 && status < 400;
  bool get isClientError => status >= 400 && status < 500;
  bool get isServerError => status >= 500 || status == 0;
  bool get isError => status >= 400 || status == 0;
  bool get isSlow => durationMs >= 500;

  String get pathWithQuery {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final path = uri.path.isEmpty ? '/' : uri.path;
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }

  String get hostWithPort {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }

  String toCurl() {
    final buffer = StringBuffer('curl -X ${method.toUpperCase()}');
    buffer.write(' "$url"');
    return buffer.toString();
  }

  factory NetworkRequestEntry.fromJson(Map<String, dynamic> json) {
    final rawTimestamp = json['timestamp'];
    DateTime parsedTime;
    if (rawTimestamp is int) {
      parsedTime = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    } else if (rawTimestamp is String) {
      parsedTime = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return NetworkRequestEntry(
      id: json['id'] as String? ?? 'req_${DateTime.now().microsecondsSinceEpoch}',
      url: json['url'] as String? ?? '',
      method: (json['method'] as String? ?? 'GET').toUpperCase(),
      status: (json['status'] as num?)?.toInt() ?? 0,
      statusText: json['statusText'] as String? ?? '',
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      initiator: json['initiator'] as String? ?? 'fetch',
      timestamp: parsedTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'method': method,
        'status': status,
        'statusText': statusText,
        'durationMs': durationMs,
        'initiator': initiator,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };
}
