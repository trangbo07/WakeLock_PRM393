import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/routine.dart';

/// SQLite CRUD for morning routines + their steps (two tables, joined on
/// routine_id). Mirrors the alarm datasource pattern (raw sqflite helpers).
class RoutineLocalDataSource {
  RoutineLocalDataSource(this._db);

  final AppDatabase _db;

  static const _routines = AppConstants.morningRoutinesTable;
  static const _steps = AppConstants.routineStepsTable;

  Future<List<MorningRoutine>> fetchAll() async {
    final db = await _db.database;
    final rows = await db.query(_routines, orderBy: 'created_at DESC');
    return Future.wait(rows.map((r) => _hydrate(db, r)));
  }

  Future<MorningRoutine?> fetchById(String id) async {
    final db = await _db.database;
    final rows = await db.query(_routines, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _hydrate(db, rows.first);
  }

  /// Replace the routine row and rewrite its steps (delete-then-insert keeps
  /// ordering/position simple).
  Future<void> upsert(MorningRoutine routine) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert(_routines, _routineToRow(routine),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete(_steps, where: 'routine_id = ?', whereArgs: [routine.id]);
      for (final s in routine.steps) {
        await txn.insert(_steps, _stepToRow(routine.id, s));
      }
    });
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete(_steps, where: 'routine_id = ?', whereArgs: [id]);
      await txn.delete(_routines, where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> setEnabled(String id, {required bool enabled}) async {
    final db = await _db.database;
    await db.update(_routines, {'is_enabled': enabled ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // --- mapping helpers (row <-> entity) ---

  Future<MorningRoutine> _hydrate(Database db, Map<String, Object?> row) async {
    final id = row['id'] as String;
    final stepRows =
        await db.query(_steps, where: 'routine_id = ?', whereArgs: [id], orderBy: 'position');
    return MorningRoutine(
      id: id,
      name: row['name'] as String? ?? '',
      isEnabled: (row['is_enabled'] as int? ?? 1) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int? ?? 0),
      steps: stepRows.map(_stepFromRow).toList(),
    );
  }

  Map<String, Object?> _routineToRow(MorningRoutine r) => {
        'id': r.id,
        'name': r.name,
        'is_enabled': r.isEnabled ? 1 : 0,
        'created_at': r.createdAt.millisecondsSinceEpoch,
      };

  Map<String, Object?> _stepToRow(String routineId, RoutineStep s) => {
        'id': s.id,
        'routine_id': routineId,
        'type': s.type.name,
        'position': s.position,
        'duration_seconds': s.durationSeconds,
        'config': jsonEncode(s.config),
      };

  RoutineStep _stepFromRow(Map<String, Object?> row) => RoutineStep(
        id: row['id'] as String,
        type: RoutineStepType.values.byName(row['type'] as String),
        position: row['position'] as int? ?? 0,
        durationSeconds: row['duration_seconds'] as int? ?? 0,
        config: (jsonDecode(row['config'] as String? ?? '{}') as Map).cast<String, dynamic>(),
      );
}
