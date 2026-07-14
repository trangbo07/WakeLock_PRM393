import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/wake_event.dart';

/// SQLite CRUD for `wake_events`. Mirrors `routine_local_datasource.dart`.
class WakeEventLocalDataSource {
  WakeEventLocalDataSource(this._db);

  final AppDatabase _db;

  static const _table = AppConstants.wakeEventsTable;

  Future<String> insertFired({required String? alarmId, required DateTime firedAt}) async {
    final db = await _db.database;
    final id = const Uuid().v4();
    await db.insert(_table, {
      'id': id,
      'alarm_id': alarmId,
      'fired_at': firedAt.millisecondsSinceEpoch,
      'dismissed_at': null,
      'mission_completed': 0,
      'routine_completed': 0,
      'photo_posted': 0,
      'wake_success': 0,
      'snooze_count': 0,
    });
    return id;
  }

  Future<void> recordMissionDismissed(String eventId, {required DateTime dismissedAt}) async {
    final db = await _db.database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [eventId]);
    if (rows.isEmpty) return;
    final firedAt = DateTime.fromMillisecondsSinceEpoch(rows.first['fired_at'] as int);
    final wakeSuccess = dismissedAt.difference(firedAt) <= WakeEvent.onTimeWindow;
    await db.update(
      _table,
      {
        'dismissed_at': dismissedAt.millisecondsSinceEpoch,
        'mission_completed': 1,
        'wake_success': wakeSuccess ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  Future<void> incrementSnooze(String eventId) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE $_table SET snooze_count = snooze_count + 1 WHERE id = ?',
      [eventId],
    );
  }

  Future<void> markRoutineCompleted(String eventId) async {
    final db = await _db.database;
    await db.update(_table, {'routine_completed': 1}, where: 'id = ?', whereArgs: [eventId]);
  }

  Future<void> markPhotoPosted(String eventId) async {
    final db = await _db.database;
    await db.update(_table, {'photo_posted': 1}, where: 'id = ?', whereArgs: [eventId]);
  }

  Future<List<WakeEvent>> getRecent({int limit = 90}) async {
    final db = await _db.database;
    final rows = await db.query(_table, orderBy: 'fired_at DESC', limit: limit);
    return rows.map(_fromRow).toList();
  }

  Future<List<WakeEvent>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(_table, orderBy: 'fired_at DESC');
    return rows.map(_fromRow).toList();
  }

  WakeEvent _fromRow(Map<String, Object?> row) => WakeEvent(
        id: row['id'] as String,
        alarmId: row['alarm_id'] as String?,
        firedAt: DateTime.fromMillisecondsSinceEpoch(row['fired_at'] as int),
        dismissedAt: row['dismissed_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row['dismissed_at'] as int),
        missionCompleted: (row['mission_completed'] as int? ?? 0) == 1,
        routineCompleted: (row['routine_completed'] as int? ?? 0) == 1,
        photoPosted: (row['photo_posted'] as int? ?? 0) == 1,
        wakeSuccess: (row['wake_success'] as int? ?? 0) == 1,
        snoozeCount: row['snooze_count'] as int? ?? 0,
      );
}
