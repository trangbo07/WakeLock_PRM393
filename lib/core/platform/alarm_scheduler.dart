import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

/// Wraps `android_alarm_manager_plus` to schedule exact, device-waking alarms
/// that fire even if the app process was killed.
///
/// The [alarmCallback] runs in a **separate background isolate** — it cannot
/// touch the app's widget tree or Riverpod state directly. From there we start
/// the foreground service + overlay window (see the hardcore feature flow).
class AlarmScheduler {
  /// Schedule a one-shot exact alarm at [when] identified by integer [id].
  ///
  /// [id] must be a stable int derived from the alarm's UUID (e.g. hashCode)
  /// so it can be cancelled/rescheduled later.
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
