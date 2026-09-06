import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkState { wifiReady, cellularHotspot, offline, unknown }

class NetworkStatusService {
  final Connectivity _connectivity;

  NetworkStatusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  static NetworkState mapConnectivityResults(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return NetworkState.offline;
    }

    if (results.length == 1 && results.first == ConnectivityResult.none) {
      return NetworkState.offline;
    }

    // Prioritize LAN/Wi-Fi / Ethernet connections for development previews
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      return NetworkState.wifiReady;
    }

    // Cellular / Hotspot
    if (results.contains(ConnectivityResult.mobile)) {
      return NetworkState.cellularHotspot;
    }

    // Web browsers / VPN endpoints
    if (results.contains(ConnectivityResult.other) ||
        results.contains(ConnectivityResult.vpn)) {
      return NetworkState.wifiReady;
    }

    if (results.contains(ConnectivityResult.none)) {
      return NetworkState.offline;
    }

    return NetworkState.unknown;
  }

  Future<NetworkState> getCurrentState() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return mapConnectivityResults(results);
    } catch (_) {
      return NetworkState.unknown;
    }
  }

  Stream<NetworkState> get onNetworkStateChanged {
    return _connectivity.onConnectivityChanged.map(mapConnectivityResults);
  }
}
