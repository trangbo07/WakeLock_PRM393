import '../../domain/entities/alarm.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../datasources/alarm_local_datasource.dart';
import '../models/alarm_model.dart';

/// SQLite-backed repository — the on-device database is the single source of
/// truth. No remote/sync layer: alarms are per-device by nature and must be
/// readable offline by the background scheduler isolate.
class LocalAlarmRepository implements AlarmRepository {
  LocalAlarmRepository(this._local);

  final AlarmLocalDataSource _local;

  @override
  Future<List<Alarm>> getAlarms() => _local.fetchAll();

  @override
  Future<Alarm?> getAlarmById(String id) => _local.fetchById(id);

  @override
  Future<void> upsertAlarm(Alarm alarm) async {
    await _local.upsert(AlarmModel.fromEntity(alarm));
    // TODO: (re)schedule the alarm via AlarmScheduler after persisting.
  }

  @override
  Future<void> deleteAlarm(String id) async {
    await _local.delete(id);
    // TODO: cancel the scheduled alarm via AlarmScheduler.
  }

  @override
  Future<void> setEnabled(String id, {required bool enabled}) =>
      _local.setEnabled(id, enabled: enabled);
}
