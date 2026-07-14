import 'package:equatable/equatable.dart';

import 'entities/wake_event.dart';

/// Aggregated streak numbers — the shape Dev 2 reads via `streakProvider` to
/// sync to `users/{uid}` for leaderboard/challenge features.
class StreakStats extends Equatable {
  const StreakStats({
    required this.current,
    required this.longest,
    required this.wakeRatePercent,
    required this.calendarByDay,
  });

  const StreakStats.empty()
      : current = 0,
        longest = 0,
        wakeRatePercent = 0,
        calendarByDay = const {};

  final int current;
  final int longest;

  /// % of days (in the observed range) that had at least one successful wake.
  final double wakeRatePercent;

  /// Local calendar day (`DateTime` truncated to midnight) -> whether that
  /// day had at least one `wakeSuccess` event. Used for the heatmap.
  final Map<DateTime, bool> calendarByDay;

  @override
  List<Object?> get props => [current, longest, wakeRatePercent, calendarByDay];
}

/// Pure streak computation from raw [WakeEvent] rows — a day counts as a win
/// if ANY event that day has `wakeSuccess == true` (mission dismissed within
/// [WakeEvent.onTimeWindow] of firing). Routine/photo completion don't gate
/// this, per the product rule chosen for this app.
class StreakCalculator {
  StreakStats calculate(List<WakeEvent> events) {
    if (events.isEmpty) return const StreakStats.empty();

    final Map<DateTime, bool> byDay = {};
    for (final e in events) {
      final day = _dayKey(e.firedAt);
      byDay[day] = (byDay[day] ?? false) || e.wakeSuccess;
    }

    final sortedDays = byDay.keys.toList()..sort();
    final wins = byDay.values.where((v) => v).length;
    final wakeRate = byDay.isEmpty ? 0.0 : wins / byDay.length * 100;

    final longest = _longestRun(sortedDays, byDay);
    final current = _currentRun(byDay);

    return StreakStats(
      current: current,
      longest: longest,
      wakeRatePercent: wakeRate,
      calendarByDay: byDay,
    );
  }

  DateTime _dayKey(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  int _longestRun(List<DateTime> sortedDays, Map<DateTime, bool> byDay) {
    var longest = 0;
    var run = 0;
    DateTime? prev;
    for (final day in sortedDays) {
      final isWin = byDay[day] ?? false;
      if (!isWin) {
        run = 0;
        prev = day;
        continue;
      }
      if (prev != null && day.difference(prev).inDays == 1) {
        run += 1;
      } else {
        run = 1;
      }
      longest = run > longest ? run : longest;
      prev = day;
    }
    return longest;
  }

  /// Streak ending at today (or yesterday, so a not-yet-happened alarm today
  /// doesn't zero out an otherwise-intact streak): walk backwards from the
  /// most recent win day while consecutive.
  int _currentRun(Map<DateTime, bool> byDay) {
    final today = _dayKey(DateTime.now());
    final hasToday = byDay.containsKey(today);
    // An explicit failure today (alarm fired, missed) breaks the streak right
    // away. If today simply hasn't happened yet, fall back to yesterday so an
    // intact streak isn't zeroed out before the day is even over.
    if (hasToday && byDay[today] == false) return 0;
    var cursor = hasToday ? today : today.subtract(const Duration(days: 1));
    var run = 0;
    while (byDay[cursor] == true) {
      run += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return run;
  }
}
