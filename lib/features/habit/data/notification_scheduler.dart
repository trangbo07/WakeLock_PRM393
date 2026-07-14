import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/utils/logger.dart';
import '../domain/entities/habit.dart';

/// Thin wrapper around `flutter_local_notifications` for habit reminders —
/// plain scheduled notifications, NOT the full-screen alarm flow. Lazily
/// initialized on first use so nothing needs to touch `core/bootstrap.dart`
/// (Dev 2-owned per docs/team-work-split.md).
class HabitNotificationScheduler {
  HabitNotificationScheduler._();

  static final HabitNotificationScheduler instance = HabitNotificationScheduler._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidInit));
    _initialized = true;
  }

  /// Deterministic notification id from the habit's UUID (FNV-1a — same
  /// approach as `AlarmScheduler.stableId`, kept local since this is an
  /// unrelated notification system, not the exact-alarm scheduler).
  int _notificationId(String habitId) {
    var hash = 0x811c9dc5;
    for (final unit in habitId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  /// (Re)schedules the daily reminder for [habit], or cancels it if the habit
  /// has no reminder time / is inactive.
  Future<void> scheduleReminder(Habit habit) async {
    try {
      await _ensureInit();
      final id = _notificationId(habit.id);
      await _plugin.cancel(id);
      if (!habit.hasReminder || !habit.isActive) return;

      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        habit.reminderHour!,
        habit.reminderMinute!,
      );
      if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

      await _plugin.zonedSchedule(
        id,
        'Nhắc thói quen',
        habit.name.isEmpty ? 'Đến giờ thực hiện thói quen của bạn' : 'Đến giờ: ${habit.name}',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habit_reminders',
            'Nhắc thói quen',
            importance: Importance.defaultImportance,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      AppLogger.w('Habit reminder schedule failed: $e');
    }
  }

  Future<void> cancelReminder(String habitId) async {
    try {
      await _ensureInit();
      await _plugin.cancel(_notificationId(habitId));
    } catch (e) {
      AppLogger.w('Habit reminder cancel failed: $e');
    }
  }
}
