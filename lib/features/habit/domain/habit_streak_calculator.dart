import 'package:equatable/equatable.dart';

import 'entities/habit.dart';

/// Per-habit streak numbers, respecting [Habit.frequencyType].
class HabitStats extends Equatable {
  const HabitStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRatePercent,
    required this.calendarByDay,
  });

  const HabitStats.empty()
      : currentStreak = 0,
        longestStreak = 0,
        completionRatePercent = 0,
        calendarByDay = const {};

  final int currentStreak;
  final int longestStreak;
  final double completionRatePercent;

  /// Local calendar day -> checked-in that day. For `daily`/`weekdays` habits
  /// this only contains "due" days (used by the heatmap). For `weeklyCount`
  /// habits it contains every day that has a check-in (there's no per-day
  /// due/not-due distinction to show).
  final Map<DateTime, bool> calendarByDay;

  @override
  List<Object?> get props =>
      [currentStreak, longestStreak, completionRatePercent, calendarByDay];
}

/// Pure streak computation for a single habit from its raw check-ins.
class HabitStreakCalculator {
  HabitStats calculate(Habit habit, List<HabitCheckin> checkins) {
    final checkedDays = checkins.map((c) => _parseDate(c.date)).toSet();
    if (checkedDays.isEmpty) return const HabitStats.empty();
    return habit.frequencyType == HabitFrequencyType.weeklyCount
        ? _calculateWeekly(habit, checkedDays)
        : _calculateDayBased(habit, checkedDays);
  }

  DateTime _dayKey(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime _parseDate(String date) {
    final parts = date.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }

  /// `daily` / `weekdays`: a streak is a run of consecutive *due* days that
  /// were all checked in — non-due days (e.g. a weekday-only habit's weekend)
  /// are skipped rather than counted as misses.
  HabitStats _calculateDayBased(Habit habit, Set<DateTime> checkedDays) {
    final today = _dayKey(DateTime.now());
    final earliest = checkedDays.reduce((a, b) => a.isBefore(b) ? a : b);
    final dueDays = <DateTime>[
      for (var d = earliest; !d.isAfter(today); d = d.add(const Duration(days: 1)))
        if (habit.isDueOn(d)) d,
    ];
    final byDay = {for (final d in dueDays) d: checkedDays.contains(d)};

    var longest = 0;
    var run = 0;
    for (final d in dueDays) {
      if (byDay[d] == true) {
        run += 1;
        longest = run > longest ? run : longest;
      } else {
        run = 0;
      }
    }

    var current = 0;
    for (var i = dueDays.length - 1; i >= 0; i--) {
      final d = dueDays[i];
      if (byDay[d] == true) {
        current += 1;
        continue;
      }
      if (d == today) continue; // today isn't over yet — don't break the streak
      break;
    }

    final rate = dueDays.isEmpty
        ? 0.0
        : byDay.values.where((v) => v).length / dueDays.length * 100;

    return HabitStats(
      currentStreak: current,
      longestStreak: longest,
      completionRatePercent: rate,
      calendarByDay: byDay,
    );
  }

  /// `weeklyCount`: a streak is a run of consecutive Mon-Sun weeks that each
  /// hit [Habit.weeklyTargetCount] check-ins.
  HabitStats _calculateWeekly(Habit habit, Set<DateTime> checkedDays) {
    final target = habit.weeklyTargetCount ?? 1;
    final today = _dayKey(DateTime.now());
    final earliest = checkedDays.reduce((a, b) => a.isBefore(b) ? a : b);
    final firstWeek = _weekStart(earliest);
    final currentWeek = _weekStart(today);

    final counts = <DateTime, int>{};
    for (final d in checkedDays) {
      final w = _weekStart(d);
      counts[w] = (counts[w] ?? 0) + 1;
    }

    final weeks = <DateTime>[
      for (var w = firstWeek; !w.isAfter(currentWeek); w = w.add(const Duration(days: 7))) w,
    ];

    var longest = 0;
    var run = 0;
    for (final w in weeks) {
      if ((counts[w] ?? 0) >= target) {
        run += 1;
        longest = run > longest ? run : longest;
      } else {
        run = 0;
      }
    }

    var current = 0;
    for (var i = weeks.length - 1; i >= 0; i--) {
      final w = weeks[i];
      if ((counts[w] ?? 0) >= target) {
        current += 1;
        continue;
      }
      if (w == currentWeek) continue; // week isn't over yet
      break;
    }

    final rate = weeks.isEmpty
        ? 0.0
        : weeks.where((w) => (counts[w] ?? 0) >= target).length / weeks.length * 100;

    return HabitStats(
      currentStreak: current,
      longestStreak: longest,
      completionRatePercent: rate,
      calendarByDay: {for (final d in checkedDays) d: true},
    );
  }

  DateTime _weekStart(DateTime d) => d.subtract(Duration(days: d.weekday - 1));
}
