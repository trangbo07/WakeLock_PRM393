import '../../domain/entities/wake_event.dart';
import '../../domain/repositories/wake_event_repository.dart';
import '../datasources/wake_event_local_datasource.dart';

class LocalWakeEventRepository implements WakeEventRepository {
  LocalWakeEventRepository(this._ds);

  final WakeEventLocalDataSource _ds;

  @override
  Future<String> insertFired({required String? alarmId, required DateTime firedAt}) =>
      _ds.insertFired(alarmId: alarmId, firedAt: firedAt);

  @override
  Future<void> recordMissionDismissed(String eventId, {required DateTime dismissedAt}) =>
      _ds.recordMissionDismissed(eventId, dismissedAt: dismissedAt);

  @override
  Future<void> incrementSnooze(String eventId) => _ds.incrementSnooze(eventId);

  @override
  Future<void> markRoutineCompleted(String eventId) => _ds.markRoutineCompleted(eventId);

  @override
  Future<void> markPhotoPosted(String eventId) => _ds.markPhotoPosted(eventId);

  @override
  Future<List<WakeEvent>> getRecent({int limit = 90}) => _ds.getRecent(limit: limit);

  @override
  Future<List<WakeEvent>> getAll() => _ds.getAll();
}
