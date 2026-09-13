import 'package:flutter_test/flutter_test.dart';
import 'package:previewport/services/shake_detector.dart';

void main() {
  test('requires a back-and-forth motion before triggering', () {
    final recognizer = ShakeGestureRecognizer(threshold: 10);
    final start = DateTime(2026, 1, 1);

    expect(recognizer.addSample(18, 0, 0, timestamp: start), isFalse);
    expect(
      recognizer.addSample(
        -18,
        0,
        0,
        timestamp: start.add(const Duration(milliseconds: 120)),
      ),
      isTrue,
    );
  });

  test('does not retrigger during its cooldown', () {
    final recognizer = ShakeGestureRecognizer(threshold: 10);
    final start = DateTime(2026, 1, 1);

    bool sample(double value, int milliseconds) => recognizer.addSample(
      value,
      0,
      0,
      timestamp: start.add(Duration(milliseconds: milliseconds)),
    );

    expect(sample(18, 0), isFalse);
    expect(sample(-18, 120), isTrue);
    expect(sample(18, 240), isFalse);
    expect(sample(-18, 360), isFalse);
    expect(sample(18, 480), isFalse);
  });

  test('ignores gentle movement and separated peaks', () {
    final recognizer = ShakeGestureRecognizer(threshold: 10);
    final start = DateTime(2026, 1, 1);

    expect(recognizer.addSample(5, 0, 0, timestamp: start), isFalse);
    expect(
      recognizer.addSample(
        -18,
        0,
        0,
        timestamp: start.add(const Duration(milliseconds: 100)),
      ),
      isFalse,
    );
    expect(
      recognizer.addSample(
        18,
        0,
        0,
        timestamp: start.add(const Duration(milliseconds: 1500)),
      ),
      isFalse,
    );
  });

  test('default threshold ignores gentle motions (2.0 m/s²) and triggers on deliberate shake (15.0 m/s²)', () {
    final recognizer = ShakeGestureRecognizer();
    final start = DateTime(2026, 1, 1);

    // Gentle motion (below 11.0 m/s²) is ignored
    expect(recognizer.addSample(2.0, 0, 0, timestamp: start), isFalse);
    expect(
      recognizer.addSample(
        -2.0,
        0,
        0,
        timestamp: start.add(const Duration(milliseconds: 150)),
      ),
      isFalse,
    );

    // Deliberate shake (above 11.0 m/s² with reversal) triggers
    final shakeStart = start.add(const Duration(milliseconds: 600));
    expect(recognizer.addSample(15.0, 0, 0, timestamp: shakeStart), isFalse);
    expect(
      recognizer.addSample(
        -15.0,
        0,
        0,
        timestamp: shakeStart.add(const Duration(milliseconds: 150)),
      ),
      isTrue,
    );
  });
}
