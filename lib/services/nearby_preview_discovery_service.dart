import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';

import '../models/nearby_preview.dart';

typedef NearbyPreviewChanged = void Function(List<NearbyPreview> previews);

/// Discovers PreviewPort CLI sessions while the app is visible on the scans tab
/// via high-reliability dual-protocol discovery (mDNS + UDP beacon).
class NearbyPreviewDiscoveryService {
  final NearbyPreviewChanged onChanged;
  final void Function(Object error)? onError;
  final Map<String, NearbyPreview> _previews = {};

  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _events;
  RawDatagramSocket? _udpSocket;
  Future<void>? _startFuture;
  bool _running = false;
  bool _disposed = false;
  int _generation = 0;

  NearbyPreviewDiscoveryService({required this.onChanged, this.onError});

  bool get isRunning => _running;

  Future<void> start() async {
    if (_disposed || kIsWeb || _running) return Future<void>.value();

    final inFlight = _startFuture;
    if (inFlight != null) {
      await inFlight;
      if (!_disposed && !_running) await start();
      return;
    }

    final future = _start(++_generation);
    _startFuture = future;
    try {
      await future;
    } finally {
      if (identical(_startFuture, future)) _startFuture = null;
    }
  }

  Future<void> _start(int generation) async {
    // 1. Dual-protocol UDP broadcast beacon listener (Port 42831)
    try {
      final udp = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        42831,
        reuseAddress: true,
        reusePort: true,
      );
      if (_disposed || generation != _generation) {
        udp.close();
      } else {
        _udpSocket = udp;
        udp.listen((RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            final datagram = udp.receive();
            if (datagram != null) {
              try {
                final jsonString = utf8.decode(datagram.data);
                final map = jsonDecode(jsonString);
                if (map is Map) {
                  final preview = NearbyPreview.fromUdpJson(Map<String, dynamic>.from(map));
                  if (preview != null && !_disposed) {
                    _previews[preview.id] = preview;
                    _emit();
                  }
                }
              } catch (_) {}
            }
          }
        });
      }
    } catch (_) {}

    // 2. Multicast DNS (Bonjour) discovery
    try {
      final discovery = BonsoirDiscovery(
        type: previewportDiscoveryType,
        printLogs: false,
      );
      await discovery.initialize();
      if (_disposed || generation != _generation) {
        await discovery.stop();
        return;
      }
      _discovery = discovery;
      _events = discovery.eventStream?.listen(
        _handleEvent,
        onError: (Object error, StackTrace _) => onError?.call(error),
      );
      await discovery.start();
      _running = true;
    } catch (error) {
      onError?.call(error);
      await _stopInternal(clear: false);
    }
  }

  void _handleEvent(BonsoirDiscoveryEvent event) {
    final discovery = _discovery;
    final service = event.service;
    if (discovery == null || service == null || _disposed) return;

    if (event is BonsoirDiscoveryServiceFoundEvent) {
      unawaited(service.resolve(discovery.serviceResolver));
      return;
    }

    if (event is BonsoirDiscoveryServiceResolvedEvent ||
        event is BonsoirDiscoveryServiceUpdatedEvent) {
      final preview = NearbyPreview.fromService(service);
      if (preview == null) return;
      _previews[preview.id] = preview;
      _emit();
      return;
    }

    if (event is BonsoirDiscoveryServiceLostEvent) {
      final id = service.attributes['sid']?.trim().isNotEmpty == true
          ? service.attributes['sid']!.trim()
          : NearbyPreview.keyForService(service);
      if (_previews.remove(id) != null) _emit();
    }
  }

  void _emit() {
    final items = _previews.values.toList()
      ..sort(
        (a, b) =>
            a.projectName.toLowerCase().compareTo(b.projectName.toLowerCase()),
      );
    onChanged(List.unmodifiable(items));
  }

  Future<void> stop() async {
    final inFlight = _startFuture;
    await _stopInternal(clear: true);
    if (inFlight != null) await inFlight;
  }

  Future<void> _stopInternal({required bool clear}) async {
    _generation++;
    final events = _events;
    _events = null;
    await events?.cancel();

    final discovery = _discovery;
    _discovery = null;
    if (discovery != null) {
      try {
        await discovery.stop();
      } catch (_) {
        // Discovery cleanup is best-effort and must never block navigation.
      }
    }

    final udp = _udpSocket;
    _udpSocket = null;
    udp?.close();

    _running = false;
    if (clear && _previews.isNotEmpty) {
      _previews.clear();
      _emit();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
  }
}
