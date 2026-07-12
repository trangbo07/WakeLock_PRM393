import 'dart:math';

/// Counts walking steps from accelerometer magnitude and estimates distance.
///
/// A step is a moderate acceleration peak (above [stepThreshold]) after the
/// motion has settled back near gravity — so genuine walking/running registers
/// but lying still does not. Distance ≈ steps × [strideMeters]. Pure logic (no
/// plugin) so it can be unit-tested with synthetic samples.
class WalkDetector {
  WalkDetector({this.stepThreshold = 11.8, this.strideMeters = 0.75});

  /// Total acceleration (m/s²) above which a step peak is registered. Walking
  /// peaks are gentler than a shake — gravity is ~9.8.
  final double stepThreshold;

  /// Average distance covered per step.
  final double strideMeters;

  bool _armed = true;
  int _steps = 0;

  int get steps => _steps;
  double get meters => _steps * strideMeters;

  /// Feed one accelerometer sample; returns true if this completed a new step.
  bool onSample(double x, double y, double z) {
    final magnitude = sqrt(x * x + y * y + z * z);
    if (magnitude > stepThreshold && _armed) {
      _armed = false;
      _steps++;
      return true;
    }
    // Re-arm once motion dips back toward resting/gravity level (~9.8).
    if (magnitude < stepThreshold - 1.5) {
      _armed = true;
    }
    return false;
  }

  void reset() {
    _armed = true;
    _steps = 0;
  }
}
