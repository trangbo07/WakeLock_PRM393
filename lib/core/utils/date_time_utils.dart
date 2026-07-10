import '../../features/alarm_management/domain/entities/weekday.dart';

/// Time/scheduling helpers shared across the app.
class DateTimeUtils {
  DateTimeUtils._();

  /// Formats hour/minute as `HH:mm`.
  static String formatHm(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Next occurrence of [hour]:[minute] respecting [repeatDays].
  ///
  /// If [repeatDays] is empty the alarm is one-shot: returns today at that time,
  /// or tomorrow if the time already passed.
  static DateTime nextOccurrence(
    int hour,
    int minute,
    Set<Weekday> repeatDays, {
    DateTime? from,
  }) {
    final now = from ?? DateTime.now();
    var candidate = DateTime(now.year, now.month, now.day, hour, minute);

    if (repeatDays.isEmpty) {
      if (!candidate.isAfter(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      return candidate;
    }

    final targetDays = repeatDays.map((d) => d.value).toSet();
    for (var i = 0; i < 8; i++) {
      final day = candidate.add(Duration(days: i));
      if (targetDays.contains(day.weekday) && day.isAfter(now)) {
        return DateTime(day.year, day.month, day.day, hour, minute);
      }
    }
    return candidate.add(const Duration(days: 1));
  }
}
