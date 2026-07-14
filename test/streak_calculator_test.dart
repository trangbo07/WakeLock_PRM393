import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_prm393/features/streak/domain/entities/wake_event.dart';
import 'package:wakelock_prm393/features/streak/domain/streak_calculator.dart';

WakeEvent _event(DateTime firedAt, {bool success = true}) => WakeEvent(
      id: firedAt.toIso8601String(),
      alarmId: 'a1',
      firedAt: firedAt,
      dismissedAt: firedAt.add(const Duration(minutes: 1)),
      missionCompleted: true,
      wakeSuccess: success,
    );

void main() {
  final calc = StreakCalculator();
  final today = DateTime.now();
  DateTime daysAgo(int n) => DateTime(today.year, today.month, today.day).subtract(Duration(days: n));

  test('empty events -> empty stats', () {
    final stats = calc.calculate(const []);
    expect(stats.current, 0);
    expect(stats.longest, 0);
    expect(stats.wakeRatePercent, 0);
  });

  test('consecutive successful days build a current streak', () {
    final events = [
      _event(daysAgo(2)),
      _event(daysAgo(1)),
      _event(daysAgo(0)),
    ];
    final stats = calc.calculate(events);
    expect(stats.current, 3);
    expect(stats.longest, 3);
    expect(stats.wakeRatePercent, 100);
  });

  test('a missed day today does not count, but breaks nothing before it happens', () {
    // No event fired today yet — yesterday's streak should still be "current".
    final events = [_event(daysAgo(2)), _event(daysAgo(1))];
    final stats = calc.calculate(events);
    expect(stats.current, 2);
  });

  test('an explicit failure today breaks the current streak immediately', () {
    final events = [
      _event(daysAgo(2)),
      _event(daysAgo(1)),
      _event(daysAgo(0), success: false),
    ];
    final stats = calc.calculate(events);
    expect(stats.current, 0);
    expect(stats.longest, 2);
  });

  test('a gap in the middle resets the run and longest tracks the best one', () {
    final events = [
      _event(daysAgo(6)),
      _event(daysAgo(5)),
      _event(daysAgo(4), success: false),
      _event(daysAgo(3)),
      _event(daysAgo(2)),
      _event(daysAgo(1)),
      _event(daysAgo(0)),
    ];
    final stats = calc.calculate(events);
    expect(stats.longest, 4); // days 3,2,1,0
    expect(stats.current, 4);
  });

  test('multiple events on the same day only count once for the day', () {
    final day = daysAgo(0);
    final events = [
      _event(day, success: false),
      _event(day.add(const Duration(hours: 1)), success: true),
    ];
    final stats = calc.calculate(events);
    // ANY success that day wins the day.
    expect(stats.calendarByDay[DateTime(day.year, day.month, day.day)], true);
  });

  test('10-minute on-time window rule matches WakeEvent.onTimeWindow', () {
    expect(WakeEvent.onTimeWindow, const Duration(minutes: 10));
  });
}
