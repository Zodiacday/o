import 'package:bonsoir/bonsoir.dart';
import 'preview_connection.dart';

const previewportDiscoveryType = '_previewport._tcp';
const previewportDiscoveryVersion = '1';

class NearbyPreview {
  final String id;
  final String projectName;
  final String url;
  final String host;
  final int port;
  final String? controlUrl;

  const NearbyPreview({
    required this.id,
    required this.projectName,
    required this.url,
    required this.host,
    required this.port,
    this.controlUrl,
  });

  String get displayEndpoint => '$host:$port';

  static NearbyPreview? fromService(BonsoirService service) {
    if (service.type != previewportDiscoveryType || service.port <= 0) {
      return null;
    }

    final attributes = service.attributes;
    if (attributes['v'] != previewportDiscoveryVersion) return null;

    final host = _usableHost(service.hostAddresses);
    if (host == null) return null;

    final projectName = (attributes['name'] ?? service.name).trim();
    if (projectName.isEmpty) return null;

    final id = (attributes['sid'] ?? '').trim().isNotEmpty
        ? attributes['sid']!.trim()
        : keyForService(service, host: host);
    final authority = host.contains(':') ? '[$host]' : host;
    final controlUrl = PreviewConnection.tryParseControlUrl(
      attributes['ctrl'],
      expectedHost: host,
    );

    return NearbyPreview(
      id: id,
      projectName: projectName,
      url: 'http://$authority:${service.port}/',
      host: host,
      port: service.port,
      controlUrl: controlUrl,
    );
  }

  static NearbyPreview? fromUdpJson(Map<String, dynamic> data) {
    if (data['app'] != 'previewport' ||
        data['v'] != previewportDiscoveryVersion) {
      return null;
    }
    final name = data['name'] as String?;
    final host = data['ip'] as String?;
    final port = data['port'] as int?;
    final sid = data['sid'] as String?;
    final ctrl = PreviewConnection.tryParseControlUrl(
      data['ctrl'] as String?,
      expectedHost: host,
    );
    if (name == null || host == null || port == null || sid == null) {
      return null;
    }

    final authority = host.contains(':') ? '[$host]' : host;
    return NearbyPreview(
      id: sid,
      projectName: name,
      url: 'http://$authority:$port/',
      host: host,
      port: port,
      controlUrl: ctrl,
    );
  }

  static String keyForService(BonsoirService service, {String? host}) {
    final resolvedHost =
        host ?? _usableHost(service.hostAddresses) ?? service.hostname ?? '';
    return '${service.name}|$resolvedHost|${service.port}';
  }

  static String? _usableHost(List<String> addresses) {
    for (final address in addresses) {
      if (address.isNotEmpty && !address.contains('%')) return address;
    }
    return null;
  }
}
