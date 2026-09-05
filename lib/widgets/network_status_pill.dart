import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/network_status_service.dart';
import '../theme/app_theme.dart';

class NetworkStatusPill extends StatefulWidget {
  final NetworkStatusService? service;

  const NetworkStatusPill({super.key, this.service});

  @override
  State<NetworkStatusPill> createState() => _NetworkStatusPillState();
}

class _NetworkStatusPillState extends State<NetworkStatusPill> {
  late final NetworkStatusService _service;
  NetworkState _state = NetworkState.unknown;
  StreamSubscription<NetworkState>? _subscription;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? NetworkStatusService();
    _initNetwork();
  }

  Future<void> _initNetwork() async {
    final current = await _service.getCurrentState();
    if (mounted) {
      setState(() => _state = current);
    }
    _subscription = _service.onNetworkStateChanged.listen((newState) {
      if (mounted) {
        setState(() => _state = newState);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _showInfoDialog(BuildContext context) {
    HapticFeedback.lightImpact();

    String title;
    String description;
    IconData icon;
    Color accentColor;

    switch (_state) {
      case NetworkState.wifiReady:
        title = 'Wi-Fi Network Active';
        description =
            'Your device is connected to Wi-Fi. Ensure your computer running PreviewPort CLI is on the same Wi-Fi network to preview instantly.';
        icon = LucideIcons.wifi;
        accentColor = const Color(0xFF00E5FF);
        break;
      case NetworkState.cellularHotspot:
        title = 'Cellular / Hotspot Active';
        description =
            'Cellular network detected.\n\n• If your laptop is connected to this phone\'s Mobile Hotspot, local previews work seamlessly.\n• If using a Cloudflare or ngrok tunnel URL, previews work over 5G/LTE.\n• Otherwise, connect this device to your computer\'s Wi-Fi network.';
        icon = LucideIcons.signal;
        accentColor = const Color(0xFFF59E0B);
        break;
      case NetworkState.offline:
        title = 'No Network Connection';
        description =
            'No active network connection detected. Enable Wi-Fi or Cellular data to connect to your preview server.';
        icon = LucideIcons.wifi_off;
        accentColor = const Color(0xFFEF4444);
        break;
      case NetworkState.unknown:
        title = 'Detecting Network';
        description = 'Scanning device network interfaces…';
        icon = LucideIcons.loader;
        accentColor = const Color(0xFF94A3B8);
        break;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: accentColor.withValues(alpha: 0.4), width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.5,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Got it'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color accentColor;
    String label;
    IconData icon;

    switch (_state) {
      case NetworkState.wifiReady:
        accentColor = const Color(0xFF00E5FF);
        label = 'Wi-Fi Ready';
        icon = LucideIcons.wifi;
        break;
      case NetworkState.cellularHotspot:
        accentColor = const Color(0xFFF59E0B);
        label = 'Cellular / Hotspot';
        icon = LucideIcons.signal;
        break;
      case NetworkState.offline:
        accentColor = const Color(0xFFEF4444);
        label = 'No Network';
        icon = LucideIcons.wifi_off;
        break;
      case NetworkState.unknown:
        accentColor = const Color(0xFF94A3B8);
        label = 'Detecting…';
        icon = LucideIcons.radio;
        break;
    }

    return Bounceable(
      scaleFactor: 0.96,
      onTap: () => _showInfoDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: accentColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              LucideIcons.info,
              size: 12,
              color: accentColor.withValues(alpha: 0.75),
            ),
          ],
        ),
      ),
    );
  }
}
