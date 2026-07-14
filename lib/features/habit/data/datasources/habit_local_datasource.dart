import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../alarm_management/domain/entities/weekday.dart';
import '../../domain/entities/habit.dart';

/// SQLite CRUD for habits + habit_checkins. Mirrors `routine_local_datasource.dart`.
class HabitLocalDataSource {
  HabitLocalDataSource(this._db);

  final AppDatabase _db;

  static const _habits = AppConstants.habitsTable;
  static const _checkins = AppConstants.habitCheckinsTable;

  Future<List<Habit>> fetchAll() async {
    final db = await _db.database;
    final rows = await db.query(_habits, orderBy: 'created_at DESC');
    return rows.map(_habitFromRow).toList();
  }

  Future<Habit?> fetchById(String id) async {
    final db = await _db.database;
    final rows = await db.query(_habits, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _habitFromRow(rows.first);
  }

  Future<void> upsert(Habit habit) async {
    final db = await _db.database;
    await db.insert(_habits, _habitToRow(habit), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete(_checkins, where: 'habit_id = ?', whereArgs: [id]);
      await txn.delete(_habits, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<HabitCheckin>> fetchCheckins(String habitId) async {
    final db = await _db.database;
    final rows = await db.query(_checkins,
        where: 'habit_id = ?', whereArgs: [habitId], orderBy: 'date DESC');
    return rows.map(_checkinFromRow).toList();
  }

  Future<bool> isCheckedOn(String habitId, String date) async {
    final db = await _db.database;
    final rows = await db.query(_checkins,
        where: 'habit_id = ? AND date = ?', whereArgs: [habitId, date], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> checkin(String habitId, {required String date}) async {
    final db = await _db.database;
    await db.insert(
      _checkins,
      {
        'id': const Uuid().v4(),
        'habit_id': habitId,
        'date': date,
        'checked_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // unique(habit_id, date)
    );
  }

  Future<void> uncheckin(String habitId, {required String date}) async {
    final db = await _db.database;
    await db.delete(_checkins, where: 'habit_id = ? AND date = ?', whereArgs: [habitId, date]);
  }

  // --- mapping helpers ---

  Habit _habitFromRow(Map<String, Object?> row) => Habit(
        id: row['id'] as String,
        name: row['name'] as String? ?? '',
        icon: row['icon'] as String? ?? 'check',
        color: row['color'] as int?,
        frequencyType: HabitFrequencyType.values.firstWhere(
          (t) => t.name == row['frequency_type'],
          orElse: () => HabitFrequencyType.daily,
        ),
        frequencyDays: (jsonDecode(row['frequency_days'] as String? ?? '[]') as List)
            .map((e) => Weekday.fromValue((e as num).toInt()))
            .toSet(),
        weeklyTargetCount: row['weekly_target_count'] as int?,
        reminderHour: row['reminder_hour'] as int?,
        reminderMinute: row['reminder_minute'] as int?,
        isActive: (row['is_active'] as int? ?? 1) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int? ?? 0),
      );

  Map<String, Object?> _habitToRow(Habit h) => {
        'id': h.id,
        'name': h.name,
        'icon': h.icon,
        'color': h.color,
        'frequency_type': h.frequencyType.name,
        'frequency_days': jsonEncode(h.frequencyDays.map((w) => w.value).toList()),
        'weekly_target_count': h.weeklyTargetCount,
        'reminder_hour': h.reminderHour,
        'reminder_minute': h.reminderMinute,
        'is_active': h.isActive ? 1 : 0,
        'created_at': h.createdAt.millisecondsSinceEpoch,
      };

  HabitCheckin _checkinFromRow(Map<String, Object?> row) => HabitCheckin(
        id: row['id'] as String,
        habitId: row['habit_id'] as String,
        date: row['date'] as String,
        checkedAt: DateTime.fromMillisecondsSinceEpoch(row['checked_at'] as int),
      );
}
