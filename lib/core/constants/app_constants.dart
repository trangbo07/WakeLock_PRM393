/// App-wide constant values (no logic).
class AppConstants {
  AppConstants._();

  static const String appName = 'WakeLock';

  /// SQLite database file + table names.
  static const String databaseFile = 'wakelock.db';
  static const String alarmsTable = 'alarms';
  static const String customRingtonesTable = 'custom_ringtones';

  /// Wake-flow tables (Ring → Mission → Routine → Photo → Streak).
  /// `wake_events` is the backbone the streak/dashboard/AI features read from.
  static const String wakeEventsTable = 'wake_events';
  static const String morningRoutinesTable = 'morning_routines';
  static const String routineStepsTable = 'routine_steps';
  static const String routineRunsTable = 'routine_runs';
  static const String morningPhotosTable = 'morning_photos';

  /// Habit tracker tables (Thói quen tab).
  static const String habitsTable = 'habits';
  static const String habitCheckinsTable = 'habit_checkins';

  /// Emergency SOS contacts (global, not per-alarm).
  static const String emergencyContactsTable = 'emergency_contacts';

  /// Default hardcore behavior toggles.
  static const int defaultShakeCount = 50;
  static const int defaultMathProblems = 3;
}
