import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_prm393/features/alarm_management/domain/entities/weekday.dart';
import 'package:wakelock_prm393/features/habit/domain/entities/habit.dart';
import 'package:wakelock_prm393/features/habit/domain/habit_streak_calculator.dart';

Habit _dailyHabit() =>
    Habit(id: 'h1', createdAt: DateTime.now(), frequencyType: HabitFrequencyType.daily);

Habit _weekdaysHabit(Set<Weekday> days) => Habit(
      id: 'h2',
      createdAt: DateTime.now(),
      frequencyType: HabitFrequencyType.weekdays,
      frequencyDays: days,
    );

Habit _weeklyCountHabit(int target) => Habit(
      id: 'h3',
      createdAt: DateTime.now(),
      frequencyType: HabitFrequencyType.weeklyCount,
      weeklyTargetCount: target,
    );

HabitCheckin _checkin(String habitId, DateTime day) => HabitCheckin(
      id: '${habitId}_${day.toIso8601String()}',
      habitId: habitId,
      date: '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
      checkedAt: day,
    );

void main() {
  final calc = HabitStreakCalculator();
  final today = DateTime.now();
  DateTime daysAgo(int n) => DateTime(today.year, today.month, today.day).subtract(Duration(days: n));

  test('no check-ins -> empty stats', () {
    final stats = calc.calculate(_dailyHabit(), const []);
    expect(stats.currentStreak, 0);
    expect(stats.longestStreak, 0);
  });

  test('daily habit: consecutive check-ins build a streak', () {
    final habit = _dailyHabit();
    final checkins = [
      _checkin(habit.id, daysAgo(2)),
      _checkin(habit.id, daysAgo(1)),
      _checkin(habit.id, daysAgo(0)),
    ];
    final stats = calc.calculate(habit, checkins);
    expect(stats.currentStreak, 3);
    expect(stats.longestStreak, 3);
    expect(stats.completionRatePercent, 100);
  });

  test('weekdays habit: only due days count, off-days do not break the streak', () {
    // Due only on today's weekday and yesterday's — simulate by picking the
    // weekday set from the last 2 days so the test is date-independent.
    final wd0 = Weekday.fromValue(daysAgo(0).weekday);
    final wd1 = Weekday.fromValue(daysAgo(1).weekday);
    final habit = _weekdaysHabit({wd0, wd1});
    final checkins = [
      _checkin(habit.id, daysAgo(1)),
      _checkin(habit.id, daysAgo(0)),
    ];
    final stats = calc.calculate(habit, checkins);
    expect(stats.currentStreak, 2);
  });

  test('weeklyCount habit: hitting the target every week builds a streak', () {
    final habit = _weeklyCountHabit(2);
    // 2 check-ins in each of the last 2 weeks.
    final checkins = [
      _checkin(habit.id, daysAgo(10)),
      _checkin(habit.id, daysAgo(9)),
      _checkin(habit.id, daysAgo(3)),
      _checkin(habit.id, daysAgo(2)),
    ];
    final stats = calc.calculate(habit, checkins);
    expect(stats.currentStreak, greaterThanOrEqualTo(1));
  });

  test('weeklyCount habit: missing the target this week does not break a streak before the week ends', () {
    final habit = _weeklyCountHabit(5); // unreachable target this (partial) week
    final checkins = [_checkin(habit.id, daysAgo(0))];
    final stats = calc.calculate(habit, checkins);
    // Current week isn't over, so it must not be counted as a miss yet.
    expect(stats.currentStreak, 0); // no prior complete week either
  });
}
