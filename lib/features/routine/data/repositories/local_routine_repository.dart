import '../../domain/entities/routine.dart';
import '../../domain/repositories/routine_repository.dart';
import '../datasources/routine_local_datasource.dart';

/// SQLite-backed [RoutineRepository]. Thin wrapper over the datasource; add
/// cross-cutting logic (e.g. scheduling reminders) here if needed later.
class LocalRoutineRepository implements RoutineRepository {
  LocalRoutineRepository(this._ds);

  final RoutineLocalDataSource _ds;

  @override
  Future<List<MorningRoutine>> getRoutines() => _ds.fetchAll();

  @override
  Future<MorningRoutine?> getRoutineById(String id) => _ds.fetchById(id);

  @override
  Future<void> upsertRoutine(MorningRoutine routine) => _ds.upsert(routine);

  @override
  Future<void> deleteRoutine(String id) => _ds.delete(id);

  @override
  Future<void> setEnabled(String id, {required bool enabled}) =>
      _ds.setEnabled(id, enabled: enabled);

  @override
  Future<void> logRun(
    String routineId, {
    required int stepsDone,
    required int stepsTotal,
    required DateTime startedAt,
    DateTime? completedAt,
  }) =>
      _ds.logRun(
        routineId,
        stepsDone: stepsDone,
        stepsTotal: stepsTotal,
        startedAt: startedAt,
        completedAt: completedAt,
      );
}
