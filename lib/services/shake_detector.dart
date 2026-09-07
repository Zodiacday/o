import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Recognizes a deliberate back-and-forth shake without treating a single
/// bump or tilt as a menu command.
class ShakeGestureRecognizer {
  /// User-accelerometer values are measured in m/s² (excluding gravity).
  /// Calibrated to an ultra-sensitive 1.5 m/s² with a single direction change requirement
  /// so an effortless, light flick of the wrist opens the controls instantly.
  final double threshold;
  final Duration maxDirectionInterval;
  final Duration cooldown;
  final int requiredDirectionChanges;

  DateTime? _lastPeakAt;
  DateTime? _lastShakeAt;
  double? _lastPeakAxis;
  int _directionChanges = 0;

  ShakeGestureRecognizer({
    this.threshold = 1.5,
    this.maxDirectionInterval = const Duration(milliseconds: 1000),
    this.cooldown = const Duration(milliseconds: 800),
    this.requiredDirectionChanges = 1,
  });

  bool addSample(double x, double y, double z, {DateTime? timestamp}) {
    final now = timestamp ?? DateTime.now();
    final magnitude = math.sqrt(x * x + y * y + z * z);
    if (magnitude < threshold) {
      _resetPeaksIfExpired(now);
      return false;
    }

    final dominantAxis = _dominantAxis(x, y, z);
    if (_lastPeakAt == null ||
        now.difference(_lastPeakAt!) > maxDirectionInterval) {
      _directionChanges = 0;
    } else if (_lastPeakAxis != null &&
        _lastPeakAxis!.sign != dominantAxis.sign) {
      _directionChanges += 1;
    }

    _lastPeakAt = now;
    _lastPeakAxis = dominantAxis;

    if (_directionChanges < requiredDirectionChanges) return false;
    if (_lastShakeAt != null && now.difference(_lastShakeAt!) < cooldown) {
      return false;
    }

    _lastShakeAt = now;
    _resetPeaks();
    return true;
  }

  double _dominantAxis(double x, double y, double z) {
    if (x.abs() >= y.abs() && x.abs() >= z.abs()) return x;
    if (y.abs() >= z.abs()) return y;
    return z;
  }

  void _resetPeaksIfExpired(DateTime now) {
    if (_lastPeakAt != null &&
        now.difference(_lastPeakAt!) > maxDirectionInterval) {
      _resetPeaks();
    }
  }

  void _resetPeaks() {
    _lastPeakAt = null;
    _lastPeakAxis = null;
    _directionChanges = 0;
  }
}

/// Listens for device motion while a preview viewer is visible.
class ShakeDetector {
  final VoidCallback onShake;
  final ShakeGestureRecognizer recognizer;
  StreamSubscription<UserAccelerometerEvent>? _subscription;

  ShakeDetector({required this.onShake, ShakeGestureRecognizer? recognizer})
    : recognizer = recognizer ?? ShakeGestureRecognizer();

  void start() {
    if (_subscription != null || kIsWeb) return;
    _subscription = userAccelerometerEventStream().listen(
      (event) {
        if (recognizer.addSample(event.x, event.y, event.z)) {
          onShake();
        }
      },
      onError: (_) {
        // Motion is an enhancement; a sensor failure must never affect the
        // preview viewer itself.
      },
      cancelOnError: false,
    );
  }

  Future<void> stop() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }
}
