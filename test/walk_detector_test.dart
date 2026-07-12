import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_prm393/features/task/domain/walk_detector.dart';

void main() {
  // One step = an acceleration peak after settling near gravity.
  void stepOnce(WalkDetector d) {
    d.onSample(0, 0, 9.8); // resting / re-arm
    d.onSample(0, 0, 14); // peak
  }

  test('counts one step per peak-after-settle and converts to meters', () {
    final d = WalkDetector(strideMeters: 0.75);
    stepOnce(d);
    stepOnce(d);
    expect(d.steps, 2);
    expect(d.meters, closeTo(1.5, 0.001));
  });

  test('a sustained peak without settling counts once', () {
    final d = WalkDetector();
    d.onSample(0, 0, 14);
    d.onSample(0, 0, 15);
    d.onSample(0, 0, 16);
    expect(d.steps, 1);
  });

  test('holding still (gravity only) registers no steps', () {
    final d = WalkDetector();
    for (var i = 0; i < 20; i++) {
      d.onSample(0, 0, 9.8);
    }
    expect(d.steps, 0);
  });

  test('reaching target meters', () {
    final d = WalkDetector(strideMeters: 0.75); // ~40 steps => 30 m
    for (var i = 0; i < 40; i++) {
      stepOnce(d);
    }
    expect(d.meters, greaterThanOrEqualTo(30));
  });

  test('reset clears steps and re-arms', () {
    final d = WalkDetector();
    stepOnce(d);
    d.reset();
    expect(d.steps, 0);
    stepOnce(d);
    expect(d.steps, 1);
  });
}
