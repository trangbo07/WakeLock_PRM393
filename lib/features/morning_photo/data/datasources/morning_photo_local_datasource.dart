import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/morning_photo.dart';

/// SQLite CRUD for morning photos (table `morning_photos`, created at DB v4).
class MorningPhotoLocalDataSource {
  MorningPhotoLocalDataSource(this._db);

  final AppDatabase _db;

  static const _table = AppConstants.morningPhotosTable;

  Future<List<MorningPhoto>> fetchAll() async {
    final db = await _db.database;
    final rows = await db.query(_table, orderBy: 'created_at DESC');
    return rows.map(_fromRow).toList();
  }

  Future<MorningPhoto?> fetchById(String id) async {
    final db = await _db.database;
    final rows = await db.query(_table, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<List<MorningPhoto>> fetchUnposted() async {
    final db = await _db.database;
    final rows = await db.query(_table,
        where: 'posted = 0', orderBy: 'created_at DESC');
    return rows.map(_fromRow).toList();
  }

  Future<void> upsert(MorningPhoto photo) async {
    final db = await _db.database;
    await db.insert(_table, _toRow(photo),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markPosted(String id, String remoteId) async {
    final db = await _db.database;
    await db.update(_table, {'posted': 1, 'remote_id': remoteId},
        where: 'id = ?', whereArgs: [id]);
  }

  // --- mapping helpers ---

  DateTime? _dt(Object? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms as int);

  MorningPhoto _fromRow(Map<String, Object?> row) => MorningPhoto(
        id: row['id'] as String,
        path: row['path'] as String,
        caption: row['caption'] as String? ?? '',
        mood: row['mood'] as String?,
        weather: row['weather'] as String?,
        wakeTime: _dt(row['wake_time']),
        alarmTime: _dt(row['alarm_time']),
        privacy: PhotoPrivacy.values
            .byName(row['privacy'] as String? ?? 'private'),
        posted: (row['posted'] as int? ?? 0) == 1,
        remoteId: row['remote_id'] as String?,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int? ?? 0),
      );

  Map<String, Object?> _toRow(MorningPhoto p) => {
        'id': p.id,
        'path': p.path,
        'caption': p.caption,
        'mood': p.mood,
        'weather': p.weather,
        'wake_time': p.wakeTime?.millisecondsSinceEpoch,
        'alarm_time': p.alarmTime?.millisecondsSinceEpoch,
        'privacy': p.privacy.name,
        'posted': p.posted ? 1 : 0,
        'remote_id': p.remoteId,
        'created_at': p.createdAt.millisecondsSinceEpoch,
      };
}
