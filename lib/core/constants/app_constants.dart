/// App-wide constant values (no logic).
class AppConstants {
  AppConstants._();

  static const String appName = 'WakeLock';

  /// SQLite database file + table names.
  static const String databaseFile = 'wakelock.db';
  static const String alarmsTable = 'alarms';

  /// Default hardcore behavior toggles.
  static const int defaultShakeCount = 50;
  static const int defaultMathProblems = 3;
}
