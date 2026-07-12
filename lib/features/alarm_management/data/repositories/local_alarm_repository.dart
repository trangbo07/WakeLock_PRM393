import '../../../../core/platform/alarm_scheduler.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../alarm_ringing/data/alarm_fire_handler.dart';
import '../../domain/entities/alarm.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../datasources/alarm_local_datasource.dart';
import '../models/alarm_model.dart';

/// SQLite-backed repository — the on-device database is the single source of
/// truth. No remote/sync layer: alarms are per-device by nature and must be
/// readable offline by the background scheduler isolate.
///
/// Persistence and OS scheduling are kept in sync here: every write that
/// changes when/whether an alarm fires also (re)schedules or cancels it.
/// Only the NEXT occurrence is scheduled; rescheduling repeating alarms after
/// they fire happens in `alarmFireHandler` (features/alarm_ringing/data/).
class LocalAlarmRepository implements AlarmRepository {
  LocalAlarmRepository(this._local, this._scheduler);

  final AlarmLocalDataSource _local;
  final AlarmScheduler _scheduler;

  @override
  Future<List<Alarm>> getAlarms() => _local.fetchAll();

  @override
  Future<Alarm?> getAlarmById(String id) => _local.fetchById(id);

  @override
  Future<void> upsertAlarm(Alarm alarm) async {
    await _local.upsert(AlarmModel.fromEntity(alarm));
    await _syncSchedule(alarm);
  }

  @override
  Future<void> deleteAlarm(String id) async {
    await _local.delete(id);
    await _scheduler.cancel(AlarmScheduler.stableId(id));
  }

  @override
  Future<void> setEnabled(String id, {required bool enabled}) async {
    await _local.setEnabled(id, enabled: enabled);
    final alarm = await _local.fetchById(id);
    if (alarm != null) await _syncSchedule(alarm);
  }

  /// Schedule the next occurrence when enabled, otherwise cancel.
  Future<void> _syncSchedule(Alarm alarm) async {
    final intId = AlarmScheduler.stableId(alarm.id);
    if (alarm.isEnabled) {
      await _scheduler.scheduleOneShot(
        intId,
        DateTimeUtils.nextOccurrence(
          alarm.hour,
          alarm.minute,
          alarm.repeatDays,
        ),
        callback: alarmFireHandler,
      );
    } else {
      await _scheduler.cancel(intId);
    }
  }
}
