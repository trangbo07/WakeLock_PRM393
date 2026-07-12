import 'dart:math';

/// Counts discrete "shakes" from accelerometer magnitude samples.
///
/// A shake is registered when total acceleration crosses [threshold] (m/s²)
/// having previously dropped below it — so one vigorous motion counts once, not
/// once per sample. Pure logic (no plugin) so it can be unit-tested by feeding
/// synthetic samples.
class ShakeDetector {
  ShakeDetector({this.threshold = 18.0});

  /// Gravity is ~9.8; a deliberate shake pushes total magnitude well above it.
  final double threshold;

  bool _armed = true;
  int _count = 0;

  int get count => _count;

  /// Feed one accelerometer sample; returns true if this sample completed a
  /// new shake.
  bool onSample(double x, double y, double z) {
    final magnitude = sqrt(x * x + y * y + z * z);
    if (magnitude > threshold && _armed) {
      _armed = false;
      _count++;
      return true;
    }
    if (magnitude < threshold * 0.6) {
      // Re-arm once motion settles, so the next shake can be counted.
      _armed = true;
    }
    return false;
  }

  void reset() {
    _armed = true;
    _count = 0;
  }
}
