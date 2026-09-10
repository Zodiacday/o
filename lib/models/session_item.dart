class SessionItem {
  final String id;
  final String url;
  final String title;
  final DateTime timestamp;
  final bool isFavorite;
  final String? controlUrl;

  SessionItem({
    required this.id,
    required this.url,
    required this.title,
    required this.timestamp,
    this.isFavorite = false,
    this.controlUrl,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.month}/${timestamp.day}';
  }

  String get displayEndpoint {
    try {
      final uri = Uri.parse(url);
      final portPart = uri.hasPort ? ':${uri.port}' : '';
      return '${uri.host}$portPart';
    } catch (_) {
      return url.replaceFirst(RegExp(r'^https?:\/\/'), '');
    }
  }

  String get displayUrl => displayEndpoint;

  SessionItem copyWith({
    String? id,
    String? url,
    String? title,
    DateTime? timestamp,
    bool? isFavorite,
    String? controlUrl,
  }) {
    return SessionItem(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
      controlUrl: controlUrl ?? this.controlUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'title': title,
    'timestamp': timestamp.toIso8601String(),
    'isFavorite': isFavorite,
    if (controlUrl != null) 'controlUrl': controlUrl,
  };

  factory SessionItem.fromJson(Map<String, dynamic> json) => SessionItem(
    id: json['id'] as String? ?? UniqueKey().toString(),
    url: json['url'] as String,
    title: json['title'] as String? ?? 'Flutter App',
    timestamp:
        DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    isFavorite: json['isFavorite'] as bool? ?? false,
    controlUrl: json['controlUrl'] as String?,
  );
}

class UniqueKey {
  static int _counter = 0;
  @override
  String toString() =>
      'session_${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
}
