import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/ringtone.dart';

/// SQLite persistence for user-added ringtones (metadata only; the audio file
/// itself lives in the app documents dir at the stored `uri` path).
class CustomRingtoneDataSource {
  CustomRingtoneDataSource(this._appDb);

  final AppDatabase _appDb;

  Future<List<Ringtone>> fetchAll() async {
    final db = await _appDb.database;
    final rows = await db.query(AppConstants.customRingtonesTable);
    return rows
        .map((r) => Ringtone(
              uri: r['uri'] as String,
              name: r['name'] as String,
              isCustom: true,
            ))
        .toList(growable: false);
  }

  Future<void> insert(Ringtone ringtone) async {
    final db = await _appDb.database;
    await db.insert(
      AppConstants.customRingtonesTable,
      {'uri': ringtone.uri, 'name': ringtone.name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String uri) async {
    final db = await _appDb.database;
    await db.delete(
      AppConstants.customRingtonesTable,
      where: 'uri = ?',
      whereArgs: [uri],
    );
  }
}
