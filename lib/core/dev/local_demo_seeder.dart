import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../database/app_database.dart';

/// Seeds the local SQLite tables that back the personal screens (Streak,
/// Dashboard, Habit) so a demo account looks fully used. Firestore data is
/// handled separately by [SampleDataSeeder]. Deterministic + idempotent: demo
/// rows carry a marker (wake_events.alarm_id / habit id prefix) so a re-seed or
/// clear removes exactly what it wrote and nothing real.
class LocalDemoSeeder {
  LocalDemoSeeder([AppDatabase? db]) : _appDb = db ?? AppDatabase.instance;

  final AppDatabase _appDb;

  static const String _demoAlarmId = 'demo_seed';
  static const String _habitPrefix = 'demo_habit_';

  static const int _wakeDays = 45; // history depth for streak/dashboard
  static const int _checkinDays = 25; // habit check-in history depth

  Future<void> seed() async {
    final db = await _appDb.database;
    await _clearDemo(db); // idempotent re-seed

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 6, 30);

    // 1) wake_events — one per day. Days 0..25 all succeed (→ current streak
    // ≈26); two misses further back so "longest" and the heatmap look real.
    final we = db.batch();
    for (var d = 0; d < _wakeDays; d++) {
      final fired = today.subtract(Duration(days: d));
      final miss = d == 26 || d == 33;
      we.insert(AppConstants.wakeEventsTable, {
        'id': 'demo_we_$d',
        'alarm_id': _demoAlarmId,
        'fired_at': fired.millisecondsSinceEpoch,
        'dismissed_at': miss
            ? null
            : fired.add(Duration(minutes: 2 + d % 5)).millisecondsSinceEpoch,
        'mission_completed': miss ? 0 : 1,
        'routine_completed': (!miss && d % 3 == 0) ? 1 : 0,
        'photo_posted': (!miss && d % 4 == 0) ? 1 : 0,
        'wake_success': miss ? 0 : 1,
        'snooze_count': d % 3,
      });
    }
    await we.commit(noResult: true);

    // 2) Habits + check-in history (daily; a small gap per habit so completion
    // rates differ). Today is always checked so current streaks look strong.
    final habits = [
      {'id': '${_habitPrefix}water', 'name': 'Uống nước', 'icon': '💧', 'created': 40},
      {'id': '${_habitPrefix}exercise', 'name': 'Tập thể dục', 'icon': '🏃', 'created': 35},
      {'id': '${_habitPrefix}meditate', 'name': 'Thiền', 'icon': '🧘', 'created': 30},
      {'id': '${_habitPrefix}read', 'name': 'Đọc sách', 'icon': '📚', 'created': 22},
    ];
    final hb = db.batch();
    for (final h in habits) {
      hb.insert(AppConstants.habitsTable, {
        'id': h['id'],
        'name': h['name'],
        'icon': h['icon'],
        'color': null,
        'frequency_type': 'daily',
        'frequency_days': '[]',
        'weekly_target_count': null,
        'reminder_hour': 7,
        'reminder_minute': 0,
        'is_active': 1,
        'created_at': today
            .subtract(Duration(days: h['created'] as int))
            .millisecondsSinceEpoch,
      });
    }
    for (var hi = 0; hi < habits.length; hi++) {
      final id = habits[hi]['id'] as String;
      for (var d = 0; d < _checkinDays; d++) {
        if (d != 0 && (d + hi) % 7 == 3) continue; // occasional gap (not today)
        final day = today.subtract(Duration(days: d));
        hb.insert(AppConstants.habitCheckinsTable, {
          'id': 'demo_ci_${hi}_$d',
          'habit_id': id,
          'date': _dateKey(day),
          'checked_at': day.millisecondsSinceEpoch,
        });
      }
    }
    await hb.commit(noResult: true);
  }

  Future<void> clear() async => _clearDemo(await _appDb.database);

  Future<void> _clearDemo(Database db) async {
    await db.delete(AppConstants.wakeEventsTable,
        where: 'alarm_id = ?', whereArgs: [_demoAlarmId]);
    await db.delete(AppConstants.habitCheckinsTable,
        where: 'habit_id LIKE ?', whereArgs: ['$_habitPrefix%']);
    await db.delete(AppConstants.habitsTable,
        where: 'id LIKE ?', whereArgs: ['$_habitPrefix%']);
  }

  String _dateKey(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}
