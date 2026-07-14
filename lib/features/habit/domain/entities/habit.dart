import 'package:equatable/equatable.dart';

import '../../../alarm_management/domain/entities/weekday.dart';

/// How often a habit is expected to be done. Stored as the enum name in
/// habits.frequency_type (SQLite).
enum HabitFrequencyType {
  /// Every day.
  daily('Hằng ngày'),

  /// Only on the selected weekdays ([Habit.frequencyDays]).
  weekdays('Chọn thứ trong tuần'),

  /// Any N times within a calendar week ([Habit.weeklyTargetCount]).
  weeklyCount('Số lần mỗi tuần');

  const HabitFrequencyType(this.label);

  final String label;
}

/// A single habit to track (e.g. "Đọc sách", "Tập thể dục").
class Habit extends Equatable {
  const Habit({
    required this.id,
    required this.createdAt,
    this.name = '',
    this.icon = 'check',
    this.color,
    this.frequencyType = HabitFrequencyType.daily,
    this.frequencyDays = const {},
    this.weeklyTargetCount,
    this.reminderHour,
    this.reminderMinute,
    this.isActive = true,
  });

  final String id;
  final String name;

  /// Emoji shown as the habit's icon.
  final String icon;

  /// ARGB color value, null = use the theme default.
  final int? color;

  final HabitFrequencyType frequencyType;

  /// Days this habit is expected, when [frequencyType] is [HabitFrequencyType.weekdays].
  final Set<Weekday> frequencyDays;

  /// Target check-ins per calendar week, when [frequencyType] is [HabitFrequencyType.weeklyCount].
  final int? weeklyTargetCount;

  final int? reminderHour;
  final int? reminderMinute;
  final bool isActive;
  final DateTime createdAt;

  bool get hasReminder => reminderHour != null && reminderMinute != null;

  /// Whether [day] is an expected day for this habit (used to compute streaks
  /// and "due today" — weeklyCount habits are due every day since the target
  /// is counted over the whole week, not pinned to specific days).
  bool isDueOn(DateTime day) {
    switch (frequencyType) {
      case HabitFrequencyType.daily:
      case HabitFrequencyType.weeklyCount:
        return true;
      case HabitFrequencyType.weekdays:
        return frequencyDays.any((w) => w.value == day.weekday);
    }
  }

  Habit copyWith({
    String? name,
    String? icon,
    int? color,
    HabitFrequencyType? frequencyType,
    Set<Weekday>? frequencyDays,
    int? weeklyTargetCount,
    int? reminderHour,
    int? reminderMinute,
    bool clearReminder = false,
    bool? isActive,
  }) =>
      Habit(
        id: id,
        createdAt: createdAt,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        frequencyType: frequencyType ?? this.frequencyType,
        frequencyDays: frequencyDays ?? this.frequencyDays,
        weeklyTargetCount: weeklyTargetCount ?? this.weeklyTargetCount,
        reminderHour: clearReminder ? null : (reminderHour ?? this.reminderHour),
        reminderMinute: clearReminder ? null : (reminderMinute ?? this.reminderMinute),
        isActive: isActive ?? this.isActive,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        icon,
        color,
        frequencyType,
        frequencyDays,
        weeklyTargetCount,
        reminderHour,
        reminderMinute,
        isActive,
        createdAt,
      ];
}

/// One check-in of a habit on a given local day ('YYYY-MM-DD').
class HabitCheckin extends Equatable {
  const HabitCheckin({
    required this.id,
    required this.habitId,
    required this.date,
    required this.checkedAt,
  });

  final String id;
  final String habitId;

  /// Local day key, 'YYYY-MM-DD' — one check-in per habit per day (enforced
  /// by a unique index in SQLite).
  final String date;
  final DateTime checkedAt;

  @override
  List<Object?> get props => [id, habitId, date, checkedAt];
}
