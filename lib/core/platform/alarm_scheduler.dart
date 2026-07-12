import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

/// Wraps `android_alarm_manager_plus` to schedule exact, device-waking alarms
/// that fire even if the app process was killed.
///
/// The fired [callback] runs in a **separate background isolate** — it cannot
/// touch the app's widget tree or Riverpod state. The app-level handler lives
/// in `features/alarm_ringing/data/alarm_fire_handler.dart` and is passed in
/// by the repository, keeping core/ free of feature imports.
class AlarmScheduler {
  /// Deterministic 31-bit positive int for AndroidAlarmManager derived from the
  /// alarm's UUID string (FNV-1a). NOT `String.hashCode`: that isn't guaranteed
  /// stable across VM versions, and the id must survive app restarts/upgrades
  /// so an existing alarm can still be cancelled or rescheduled.
  static int stableId(String alarmId) {
    var hash = 0x811c9dc5; // FNV-1a 32-bit offset basis
    for (final unit in alarmId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF; // FNV prime, keep 32 bits
    }
    return hash & 0x7FFFFFFF;
  }

  /// Schedule a one-shot exact alarm at [when] identified by integer [id]
  /// (from [stableId]). [callback] must be a top-level function annotated with
  /// `@pragma('vm:entry-point')`.
  Future<bool> scheduleOneShot(
    int id,
    DateTime when, {
    required void Function(int) callback,
  }) {
    return AndroidAlarmManager.oneShotAt(
      when,
      id,
      callback,
      exact: true,
      wakeup: true,
      alarmClock: true,
      rescheduleOnReboot: true,
    );
  }

  Future<bool> cancel(int id) => AndroidAlarmManager.cancel(id);
}
