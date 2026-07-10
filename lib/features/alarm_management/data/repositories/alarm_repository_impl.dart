import '../../domain/entities/alarm.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../datasources/alarm_local_cache_datasource.dart';
import '../datasources/alarm_remote_datasource.dart';
import '../models/alarm_model.dart';

/// Remote-first repository: reads/writes Supabase and mirrors every read into
/// the local cache so the alarm scheduler can fire offline.
class AlarmRepositoryImpl implements AlarmRepository {
  AlarmRepositoryImpl(this._remote, this._cache);

  final AlarmRemoteDataSource _remote;
  final AlarmLocalCacheDataSource _cache;

  @override
  Future<List<Alarm>> getAlarms() async {
    try {
      final remote = await _remote.fetchAll();
      await _cache.writeAll(remote);
      return remote;
    } catch (_) {
      // Offline fallback: serve the last-known cached list.
      return _cache.readAll();
    }
  }

  @override
  Future<Alarm?> getAlarmById(String id) async {
    final all = await getAlarms();
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  Future<void> upsertAlarm(Alarm alarm) async {
    await _remote.upsert(AlarmModel.fromEntity(alarm));
    await getAlarms(); // refresh cache
    // TODO: (re)schedule the alarm via AlarmScheduler after persisting.
  }

  @override
  Future<void> deleteAlarm(String id) async {
    await _remote.delete(id);
    await getAlarms();
    // TODO: cancel the scheduled alarm via AlarmScheduler.
  }

  @override
  Future<void> setEnabled(String id, {required bool enabled}) async {
    final alarm = await getAlarmById(id);
    if (alarm == null) return;
    await upsertAlarm(alarm.copyWith(isEnabled: enabled));
  }
}
