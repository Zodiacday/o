import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../widgets/viewport_switcher_sheet.dart';

/// Reads the actual device model name from native platform channels
/// and combines it with [MediaQuery] metrics to build a fully-populated
/// [SimulatedDeviceProfile].
///
/// Unlike the old heuristic approach (guessing device from screen dimensions),
/// this reads the authoritative model string directly from:
/// - iOS: `UIDevice.modelIdentifier` → mapped to marketing name
/// - Android: `Build.MODEL` + `Build.MANUFACTURER`
class DeviceViewportSensor {
  DeviceViewportSensor._();

  static const _channel = MethodChannel('com.previewport/device_info');

  // ─── Cached native info (fetched once) ─────────────────────────────
  static Map<String, dynamic>? _cachedInfo;

  /// Fetches device info from the native platform channel.
  /// Caches the result so the channel is only called once per app session.
  static Future<Map<String, dynamic>> _fetchNativeInfo() async {
    if (_cachedInfo != null) return _cachedInfo!;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getDeviceInfo');
      _cachedInfo = result ?? {};
    } on PlatformException {
      _cachedInfo = {};
    } on MissingPluginException {
      // Running in test or on a platform without the channel.
      _cachedInfo = {};
    }
    return _cachedInfo!;
  }

  /// Clears the cached native info. Useful for testing.
  @visibleForTesting
  static void resetCache() => _cachedInfo = null;

  // ─── Form Factor Classification ────────────────────────────────────

  /// Classifies the device into a form-factor category based on its
  /// logical screen dimensions.
  static String classifyFormFactor(double width, double height) {
    final shortSide = width < height ? width : height;
    final longSide = width > height ? width : height;

    if (shortSide >= 600 || longSide >= 1000) return 'tablet';
    if (shortSide <= 360) return 'compact';
    if (shortSide >= 420) return 'large';
    return 'standard';
  }

  // ─── Corner Radius Estimation ──────────────────────────────────────

  /// Estimates the device's corner radius based on safe-area presence.
  static double estimateCornerRadius(
    double dpr,
    bool hasSafeAreaTop,
    String platform,
  ) {
    if (!hasSafeAreaTop) {
      return platform == 'ios' ? 18.0 : 12.0;
    }
    if (platform == 'ios') {
      return dpr >= 3.0 ? 47.0 : 39.0;
    }
    return 28.0;
  }

  // ─── Main Detection ────────────────────────────────────────────────

  /// Reads the real device model from the native platform channel and
  /// combines it with [MediaQuery] metrics to build a [SimulatedDeviceProfile].
  ///
  /// Call this once (e.g. in `didChangeDependencies`) and cache the result.
  /// The platform channel is only invoked once per app session.
  static Future<SimulatedDeviceProfile> detect(BuildContext context) async {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final padding = mq.padding;
    final dpr = mq.devicePixelRatio;
    final platform = Platform.isIOS ? 'ios' : 'android';

    final width = size.width;
    final height = size.height;
    final topInset = padding.top;
    final bottomInset = padding.bottom;

    // ── Get authoritative model name from native ──
    final info = await _fetchNativeInfo();
    final nativeModel = info['model'] as String? ?? '';
    final deviceName = nativeModel.isNotEmpty
        ? nativeModel
        : _fallbackName(width, height, dpr, platform);

    // ── Classify ──
    final hasDynamicIsland = platform == 'ios' && topInset >= 54;
    final hasNotch = !hasDynamicIsland &&
        ((platform == 'ios' && topInset >= 44 && topInset < 54) ||
         (platform == 'android' && topInset > 24));
    final formFactor = classifyFormFactor(width, height);
    final cornerRadius = estimateCornerRadius(dpr, topInset > 20, platform);

    // ── Build description ──
    final dprLabel = '@${dpr.toStringAsFixed(dpr.truncateToDouble() == dpr ? 0 : 1)}x';
    final featureLabel = hasDynamicIsland
        ? 'Dynamic Island'
        : hasNotch
            ? 'Notch'
            : 'Flat';
    final formLabel = formFactor[0].toUpperCase() + formFactor.substring(1);
    final description =
        '${width.round()} × ${height.round()} pt · $dprLabel · $featureLabel · $formLabel';

    return SimulatedDeviceProfile(
      id: 'native',
      name: deviceName,
      description: description,
      width: width,
      height: height,
      topInset: topInset,
      bottomInset: bottomInset,
      cornerRadius: cornerRadius,
      hasDynamicIsland: hasDynamicIsland,
      hasNotch: hasNotch,
      icon: platform == 'ios'
          ? const IconData(0xe32c, fontFamily: 'MaterialIcons')
          : const IconData(0xe325, fontFamily: 'MaterialIcons'),
      isNativeDevice: true,
      devicePixelRatio: dpr,
      formFactor: formFactor,
    );
  }

  /// Synchronous detection using only [MediaQuery] data.
  /// Used as immediate fallback before the async channel responds.
  static SimulatedDeviceProfile detectSync(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final padding = mq.padding;
    final dpr = mq.devicePixelRatio;
    final platform = Platform.isIOS ? 'ios' : 'android';

    final width = size.width;
    final height = size.height;
    final topInset = padding.top;
    final bottomInset = padding.bottom;

    // Use cached native name if available, otherwise generic fallback.
    final info = _cachedInfo;
    final nativeModel = info?['model'] as String? ?? '';
    final deviceName = nativeModel.isNotEmpty
        ? nativeModel
        : _fallbackName(width, height, dpr, platform);

    final hasDynamicIsland = platform == 'ios' && topInset >= 54;
    final hasNotch = !hasDynamicIsland &&
        ((platform == 'ios' && topInset >= 44 && topInset < 54) ||
         (platform == 'android' && topInset > 24));
    final formFactor = classifyFormFactor(width, height);
    final cornerRadius = estimateCornerRadius(dpr, topInset > 20, platform);

    final dprLabel = '@${dpr.toStringAsFixed(dpr.truncateToDouble() == dpr ? 0 : 1)}x';
    final featureLabel = hasDynamicIsland
        ? 'Dynamic Island'
        : hasNotch
            ? 'Notch'
            : 'Flat';
    final formLabel = formFactor[0].toUpperCase() + formFactor.substring(1);
    final description =
        '${width.round()} × ${height.round()} pt · $dprLabel · $featureLabel · $formLabel';

    return SimulatedDeviceProfile(
      id: 'native',
      name: deviceName,
      description: description,
      width: width,
      height: height,
      topInset: topInset,
      bottomInset: bottomInset,
      cornerRadius: cornerRadius,
      hasDynamicIsland: hasDynamicIsland,
      hasNotch: hasNotch,
      icon: platform == 'ios'
          ? const IconData(0xe32c, fontFamily: 'MaterialIcons')
          : const IconData(0xe325, fontFamily: 'MaterialIcons'),
      isNativeDevice: true,
      devicePixelRatio: dpr,
      formFactor: formFactor,
    );
  }

  /// Generic fallback name when the platform channel is unavailable.
  static String _fallbackName(
    double width,
    double height,
    double dpr,
    String platform,
  ) {
    final os = platform == 'ios' ? 'iOS' : 'Android';
    return '$os ${width.round()}×${height.round()} @${dpr.toStringAsFixed(1)}x';
  }
}
