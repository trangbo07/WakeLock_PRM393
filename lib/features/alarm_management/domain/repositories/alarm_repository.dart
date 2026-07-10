import '../entities/alarm.dart';

/// Abstraction over alarm persistence. Backed by Supabase (remote) mirrored to
/// a local cache so scheduling works offline.
abstract interface class AlarmRepository {
  Future<List<Alarm>> getAlarms();
  Future<Alarm?> getAlarmById(String id);
  Future<void> upsertAlarm(Alarm alarm);
  Future<void> deleteAlarm(String id);
  Future<void> setEnabled(String id, {required bool enabled});
}
