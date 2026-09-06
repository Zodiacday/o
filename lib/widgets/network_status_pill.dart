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
    if (mounted) setState(() => _state = current);
    _subscription = _service.onNetworkStateChanged.listen((newState) {
      if (mounted) setState(() => _state = newState);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _showInfoSheet(BuildContext context) {
    HapticFeedback.lightImpact();

    final details = switch (_state) {
      NetworkState.wifiReady => (
          title: 'Same Wi-Fi recommended',
          description:
              'For local previews, keep your phone and development computer on the same Wi-Fi network.',
          icon: LucideIcons.wifi,
          color: AppTheme.cyan,
        ),
      NetworkState.cellularHotspot => (
          title: 'Cellular connection',
          description:
              'A local preview works through a phone hotspot or a URL that is reachable over the internet.',
          icon: LucideIcons.signal,
          color: AppTheme.warning,
        ),
      NetworkState.offline => (
          title: 'Offline',
          description:
              'Connect to Wi-Fi or cellular data before opening a preview.',
          icon: LucideIcons.wifi_off,
          color: AppTheme.danger,
        ),
      NetworkState.unknown => (
          title: 'Checking network',
          description: 'PreviewPort is checking the device connection.',
          icon: LucideIcons.loader,
          color: AppTheme.textSecondary,
        ),
    };

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 34,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Icon(details.icon, size: 20, color: details.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      details.title,
                      style: GoogleFonts.inter(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 19,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                details.description,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1, color: AppTheme.borderSubtle),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  'PreviewPort does not treat this status as proof that a server is reachable.',
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final details = switch (_state) {
      NetworkState.wifiReady => (color: AppTheme.cyan, label: 'Same Wi-Fi recommended'),
      NetworkState.cellularHotspot => (color: AppTheme.warning, label: 'Cellular connection'),
      NetworkState.offline => (color: AppTheme.danger, label: 'Offline — connect to a network'),
      NetworkState.unknown => (color: AppTheme.textSecondary, label: 'Checking network…'),
    };

    return Semantics(
      button: true,
      label: 'Network status: ${details.label}',
      hint: 'Tap for connection details',
      child: Bounceable(
        scaleFactor: 0.96,
        onTap: () => _showInfoSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: details.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                details.label,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                LucideIcons.info,
                size: 12,
                color: details.color.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
