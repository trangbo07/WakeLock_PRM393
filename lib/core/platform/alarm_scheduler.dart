import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

/// Wraps `android_alarm_manager_plus` to schedule exact, device-waking alarms
/// that fire even if the app process was killed.
///
/// The [alarmCallback] runs in a **separate background isolate** — it cannot
/// touch the app's widget tree or Riverpod state directly. From there we start
/// the foreground service + overlay window (see the hardcore feature flow).
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

  /// Schedule a one-shot exact alarm at [when] identified by integer [id].
  ///
  /// [id] must come from [stableId] so it can be cancelled/rescheduled later.
  Future<bool> scheduleOneShot(int id, DateTime when) {
    return AndroidAlarmManager.oneShotAt(
      when,
      id,
      alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true,
      rescheduleOnReboot: true,
    );
  }

  Future<bool> cancel(int id) => AndroidAlarmManager.cancel(id);
}

/// Top-level entry point executed in a background isolate when an alarm fires.
///
/// Keep it minimal and self-contained. TODO:
///   1. Start [ForegroundServiceController] (anti-kill).
///   2. Show the [OverlayService] ringing window over the lock screen.
///   3. Start ringtone playback + volume lock.
@pragma('vm:entry-point')
void alarmCallback(int id) {
  // TODO: trigger foreground service + overlay + ringtone for alarm [id].
}
