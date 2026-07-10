/// App-wide constant values (no logic).
class AppConstants {
  AppConstants._();

  static const String appName = 'WakeLock';

  /// Supabase table names.
  static const String alarmsTable = 'alarms';

  /// SharedPreferences keys.
  static const String cachedAlarmsKey = 'cached_alarms';

  /// Default hardcore behavior toggles.
  static const int defaultShakeCount = 50;
  static const int defaultMathProblems = 3;
}
