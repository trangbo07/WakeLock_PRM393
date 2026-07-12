import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../models/alarm_model.dart';

/// SQLite CRUD for the alarms table. This is the app's only alarm store —
/// readable from the background alarm isolate with no network.
class AlarmLocalDataSource {
  AlarmLocalDataSource(this._appDb);

  final AppDatabase _appDb;

  Future<List<AlarmModel>> fetchAll() async {
    final db = await _appDb.database;
    final rows = await db.query(
      AppConstants.alarmsTable,
      orderBy: 'hour, minute',
    );
    return rows.map(AlarmModel.fromDbRow).toList(growable: false);
  }

  Future<AlarmModel?> fetchById(String id) async {
    final db = await _appDb.database;
    final rows = await db.query(
      AppConstants.alarmsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : AlarmModel.fromDbRow(rows.first);
  }

  Future<void> upsert(AlarmModel alarm) async {
    final db = await _appDb.database;
    await db.insert(
      AppConstants.alarmsTable,
      alarm.toDbRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await _appDb.database;
    await db.delete(
      AppConstants.alarmsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setEnabled(String id, {required bool enabled}) async {
    final db = await _appDb.database;
    await db.update(
      AppConstants.alarmsTable,
      {'is_enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
