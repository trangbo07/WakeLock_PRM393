import '../entities/routine.dart';

/// Persistence contract for morning routines. Implemented locally over SQLite
/// (see LocalRoutineRepository). Routines are per-device offline data.
abstract class RoutineRepository {
  Future<List<MorningRoutine>> getRoutines();
  Future<MorningRoutine?> getRoutineById(String id);
  Future<void> upsertRoutine(MorningRoutine routine);
  Future<void> deleteRoutine(String id);
  Future<void> setEnabled(String id, {required bool enabled});
}
