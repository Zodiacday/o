import 'dart:io' show Platform;
import 'package:flutter/widgets.dart';
import '../widgets/viewport_switcher_sheet.dart';

/// Lightweight sensor that reads the real phone's hardware screen properties
/// from [MediaQuery] and [Platform], then builds a fully-populated
/// [SimulatedDeviceProfile] for the native device.
class DeviceViewportSensor {
  DeviceViewportSensor._();

  // ─── Device Lookup Table ───────────────────────────────────────────
  // Key: "$width×$height" in logical points.
  // Entries sorted by release recency. DPR is checked as a tie-breaker
  // when two devices share the same logical size.

  static const _knownDevices = <String, _DeviceEntry>{
    // iPhone SE (2nd / 3rd gen)
    '375×667': _DeviceEntry('iPhone SE', 2.0, true, false, false),
    // iPhone 8 Plus / 7 Plus / 6s Plus
    '414×736': _DeviceEntry('iPhone 8 Plus', 3.0, true, false, false),
    // iPhone X / XS / 11 Pro
    '375×812': _DeviceEntry('iPhone X / XS', 3.0, true, false, true),
    // iPhone XR / 11
    '414×896': _DeviceEntry('iPhone XR / 11', 2.0, true, false, true),
    // iPhone XS Max / 11 Pro Max
    '414×896@3': _DeviceEntry('iPhone XS Max', 3.0, true, false, true),
    // iPhone 12 mini / 13 mini
    '360×780': _DeviceEntry('iPhone 12 mini', 3.0, true, false, true),
    // iPhone 12 / 12 Pro / 13 / 13 Pro / 14
    '390×844': _DeviceEntry('iPhone 12 / 13 / 14', 3.0, true, false, true),
    // iPhone 12 Pro Max / 13 Pro Max
    '428×926': _DeviceEntry('iPhone 13 Pro Max', 3.0, true, false, true),
    // iPhone 14 Pro
    '393×852': _DeviceEntry('iPhone 14 Pro', 3.0, true, true, false),
    // iPhone 14 Pro Max / 15 Plus / 15 Pro Max / 16 Plus / 16 Pro Max
    '430×932': _DeviceEntry('iPhone 15 Pro Max', 3.0, true, true, false),
    // iPhone 16 Pro
    '402×874': _DeviceEntry('iPhone 16 Pro', 3.0, true, true, false),
    // iPhone 16 Pro Max
    '440×956': _DeviceEntry('iPhone 16 Pro Max', 3.0, true, true, false),
    // iPad Mini (6th gen)
    '744×1133': _DeviceEntry('iPad Mini', 2.0, true, false, false),
    // iPad Air 11"
    '820×1180': _DeviceEntry('iPad Air 11″', 2.0, true, false, false),
    // iPad Pro 11"
    '834×1194': _DeviceEntry('iPad Pro 11″', 2.0, true, false, false),
    // iPad Pro 13"
    '1024×1366': _DeviceEntry('iPad Pro 13″', 2.0, true, false, false),
    // Pixel 7 / 7a / 8 / 8a
    '412×915': _DeviceEntry('Pixel 7 / 8', 2.625, false, false, true),
    // Pixel 8 Pro
    '412×892': _DeviceEntry('Pixel 8 Pro', 3.5, false, false, true),
    // Pixel 9
    '412×922': _DeviceEntry('Pixel 9', 2.625, false, false, true),
    // Pixel 9 Pro
    '411×914': _DeviceEntry('Pixel 9 Pro', 2.75, false, false, false),
    // Samsung Galaxy S24 Ultra
    '412×883': _DeviceEntry('Galaxy S24 Ultra', 3.0, false, false, true),
  };

  // ─── Form Factor Classification ────────────────────────────────────

  /// Classifies the device into a form-factor category based on its
  /// logical screen dimensions.
  static String classifyFormFactor(double width, double height) {
    // Use the shorter dimension (portrait width) for classification.
    final shortSide = width < height ? width : height;
    final longSide = width > height ? width : height;

    if (shortSide >= 600 || longSide >= 1000) return 'tablet';
    if (shortSide <= 360) return 'compact';
    if (shortSide >= 420) return 'large';
    return 'standard';
  }

  // ─── Device Name Matching ──────────────────────────────────────────

  /// Best-effort match of screen dimensions against the lookup table.
  /// Returns a human-readable device name or a generic fallback.
  static String matchDeviceName(
    double width,
    double height,
    double dpr,
    String platform,
  ) {
    final key = '${width.round()}×${height.round()}';

    // Try exact match first.
    final exact = _knownDevices[key];
    if (exact != null) {
      // Check DPR-disambiguated key if multiple devices share the same size.
      final dprKey = '$key@${dpr.round()}';
      final dprMatch = _knownDevices[dprKey];
      if (dprMatch != null) return dprMatch.name;
      return exact.name;
    }

    // Fallback: generic label.
    final os = platform == 'ios' ? 'iOS' : 'Android';
    return '$os ${width.round()}×${height.round()} @${dpr.toStringAsFixed(1)}x';
  }

  // ─── Corner Radius Estimation ──────────────────────────────────────

  /// Estimates the device's corner radius based on safe-area presence
  /// and DPR heuristics.
  static double estimateCornerRadius(
    double dpr,
    bool hasSafeAreaTop,
    String platform,
  ) {
    if (!hasSafeAreaTop) {
      // Flat-screen device (iPhone SE, older Android, iPad without rounded corners).
      return platform == 'ios' ? 18.0 : 12.0;
    }
    // Modern rounded-display device.
    if (platform == 'ios') {
      return dpr >= 3.0 ? 47.0 : 39.0;
    }
    // Android: varies wildly, use sensible default.
    return 28.0;
  }

  // ─── Notch / Dynamic Island Detection ──────────────────────────────

  static bool _detectDynamicIsland(
    double topInset,
    String platform,
    double width,
    double height,
  ) {
    if (platform != 'ios') return false;
    // Dynamic Island devices have top insets of 59pt (iPhone 14 Pro+).
    return topInset >= 54;
  }

  static bool _detectNotch(
    double topInset,
    String platform,
    bool hasDynamicIsland,
  ) {
    if (hasDynamicIsland) return false;
    if (platform == 'ios') {
      // Notch iPhones have 44pt or 47pt top insets.
      return topInset >= 44 && topInset < 54;
    }
    // Android: any top inset > 24pt usually means a notch/punch-hole.
    return topInset > 24;
  }

  // ─── Main Detection ────────────────────────────────────────────────

  /// Reads the real hardware properties from [MediaQuery] and [Platform],
  /// returning a fully-populated [SimulatedDeviceProfile].
  static SimulatedDeviceProfile detect(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final padding = mq.padding;
    final dpr = mq.devicePixelRatio;
    final platform = Platform.isIOS ? 'ios' : 'android';

    final width = size.width;
    final height = size.height;
    final topInset = padding.top;
    final bottomInset = padding.bottom;

    final hasDynamicIsland = _detectDynamicIsland(topInset, platform, width, height);
    final hasNotch = _detectNotch(topInset, platform, hasDynamicIsland);
    final formFactor = classifyFormFactor(width, height);
    final deviceName = matchDeviceName(width, height, dpr, platform);
    final cornerRadius = estimateCornerRadius(dpr, topInset > 20, platform);

    // Build the description string with real specs.
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
}

/// Internal lookup entry for known device models.
class _DeviceEntry {
  final String name;
  final double dpr;
  final bool isApple;
  final bool hasDynamicIsland;
  final bool hasNotch;

  const _DeviceEntry(this.name, this.dpr, this.isApple, this.hasDynamicIsland, this.hasNotch);
}
