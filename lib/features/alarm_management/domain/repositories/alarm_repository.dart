import '../entities/alarm.dart';

/// Abstraction over alarm persistence. Backed by on-device SQLite so the
/// background scheduler can read alarm config fully offline.
abstract interface class AlarmRepository {
  Future<List<Alarm>> getAlarms();
  Future<Alarm?> getAlarmById(String id);
  Future<void> upsertAlarm(Alarm alarm);
  Future<void> deleteAlarm(String id);
  Future<void> setEnabled(String id, {required bool enabled});
}
