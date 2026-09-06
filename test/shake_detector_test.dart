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
      isFalse,
    );
    expect(
      recognizer.addSample(
        18,
        0,
        0,
        timestamp: start.add(const Duration(milliseconds: 240)),
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
    expect(sample(-18, 120), isFalse);
    expect(sample(18, 240), isTrue);
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
        timestamp: start.add(const Duration(milliseconds: 1000)),
      ),
      isFalse,
    );
  });
}
