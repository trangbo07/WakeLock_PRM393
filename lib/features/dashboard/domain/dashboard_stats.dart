import 'package:equatable/equatable.dart';

import '../../habit/domain/entities/habit.dart';
import '../../habit/domain/habit_streak_calculator.dart';
import '../../streak/domain/entities/wake_event.dart';

/// One point on the weekly wake-rate bar chart.
class WeeklyWakeRate extends Equatable {
  const WeeklyWakeRate({required this.weekStart, required this.ratePercent});

  final DateTime weekStart;
  final double ratePercent;

  @override
  List<Object?> get props => [weekStart, ratePercent];
}

class DashboardStats extends Equatable {
  const DashboardStats({
    required this.wakeRate7dPercent,
    required this.wakeRate30dPercent,
    required this.avgDismissDelayMinutes,
    required this.avgSnoozeCount,
    required this.habitCompletionRatePercent,
    required this.weeklyWakeRates,
  });

  const DashboardStats.empty()
      : wakeRate7dPercent = 0,
        wakeRate30dPercent = 0,
        avgDismissDelayMinutes = 0,
        avgSnoozeCount = 0,
        habitCompletionRatePercent = 0,
        weeklyWakeRates = const [];

  final double wakeRate7dPercent;
  final double wakeRate30dPercent;
  final double avgDismissDelayMinutes;
  final double avgSnoozeCount;

  /// Average of each active habit's own completion rate (see
  /// `HabitStreakCalculator`), which already accounts for each habit's
  /// frequency type.
  final double habitCompletionRatePercent;

  /// Last 6 ISO weeks (Mon-Sun), oldest first.
  final List<WeeklyWakeRate> weeklyWakeRates;

  @override
  List<Object?> get props => [
        wakeRate7dPercent,
        wakeRate30dPercent,
        avgDismissDelayMinutes,
        avgSnoozeCount,
        habitCompletionRatePercent,
        weeklyWakeRates,
      ];
}

/// Aggregates `wake_events` + habit check-ins into dashboard numbers. Pure
/// Dart — the async DB reads happen in `dashboard_providers.dart`.
class DashboardCalculator {
  DashboardStats calculate({
    required List<WakeEvent> events,
    required List<Habit> habits,
    required List<List<HabitCheckin>> checkinsPerHabit,
  }) {
    final now = DateTime.now();
    final rate7 = _wakeRate(events, since: now.subtract(const Duration(days: 7)));
    final rate30 = _wakeRate(events, since: now.subtract(const Duration(days: 30)));

    final recent = events.where((e) => e.firedAt.isAfter(now.subtract(const Duration(days: 30))));
    final dismissed = recent.where((e) => e.dismissedAt != null).toList();
    final avgDelay = dismissed.isEmpty
        ? 0.0
        : dismissed.map((e) => e.dismissedAt!.difference(e.firedAt).inSeconds / 60.0).reduce((a, b) => a + b) /
            dismissed.length;
    final avgSnooze = recent.isEmpty
        ? 0.0
        : recent.map((e) => e.snoozeCount).reduce((a, b) => a + b) / recent.length;

    final activeHabits = habits.where((h) => h.isActive).toList();
    var habitRate = 0.0;
    if (activeHabits.isNotEmpty) {
      final calc = HabitStreakCalculator();
      var sum = 0.0;
      for (var i = 0; i < activeHabits.length; i++) {
        sum += calc.calculate(activeHabits[i], checkinsPerHabit[i]).completionRatePercent;
      }
      habitRate = sum / activeHabits.length;
    }

    final weekly = _weeklyRates(events, weeks: 6);

    return DashboardStats(
      wakeRate7dPercent: rate7,
      wakeRate30dPercent: rate30,
      avgDismissDelayMinutes: avgDelay,
      avgSnoozeCount: avgSnooze,
      habitCompletionRatePercent: habitRate,
      weeklyWakeRates: weekly,
    );
  }

  double _wakeRate(List<WakeEvent> events, {required DateTime since}) {
    final window = events.where((e) => e.firedAt.isAfter(since)).toList();
    if (window.isEmpty) return 0.0;
    final wins = window.where((e) => e.wakeSuccess).length;
    return wins / window.length * 100;
  }

  DateTime _weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  List<WeeklyWakeRate> _weeklyRates(List<WakeEvent> events, {required int weeks}) {
    final currentWeek = _weekStart(DateTime.now());
    final result = <WeeklyWakeRate>[];
    for (var i = weeks - 1; i >= 0; i--) {
      final weekStart = currentWeek.subtract(Duration(days: 7 * i));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final inWeek =
          events.where((e) => !e.firedAt.isBefore(weekStart) && e.firedAt.isBefore(weekEnd)).toList();
      final rate =
          inWeek.isEmpty ? 0.0 : inWeek.where((e) => e.wakeSuccess).length / inWeek.length * 100;
      result.add(WeeklyWakeRate(weekStart: weekStart, ratePercent: rate));
    }
    return result;
  }
}
