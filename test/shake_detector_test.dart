import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_prm393/features/task/domain/shake_detector.dart';

void main() {
  // One shake = spike above threshold after settling below it.
  void shakeOnce(ShakeDetector d) {
    d.onSample(0, 0, 2); // settle (below re-arm level)
    d.onSample(0, 0, 30); // spike
  }

  test('counts one shake per spike-after-settle', () {
    final d = ShakeDetector();
    shakeOnce(d);
    expect(d.count, 1);
    shakeOnce(d);
    expect(d.count, 2);
  });

  test('a sustained spike without settling counts only once', () {
    final d = ShakeDetector();
    d.onSample(0, 0, 30);
    d.onSample(0, 0, 31);
    d.onSample(0, 0, 32);
    expect(d.count, 1);
  });

  test('gravity-only samples never register a shake', () {
    final d = ShakeDetector();
    for (var i = 0; i < 10; i++) {
      d.onSample(0, 0, 9.8);
    }
    expect(d.count, 0);
  });

  test('reset clears count and re-arms', () {
    final d = ShakeDetector();
    shakeOnce(d);
    d.reset();
    expect(d.count, 0);
    shakeOnce(d);
    expect(d.count, 1);
  });
}
