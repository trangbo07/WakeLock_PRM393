import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../datasources/habit_local_datasource.dart';

class LocalHabitRepository implements HabitRepository {
  LocalHabitRepository(this._ds);

  final HabitLocalDataSource _ds;

  @override
  Future<List<Habit>> getHabits() => _ds.fetchAll();

  @override
  Future<Habit?> getHabitById(String id) => _ds.fetchById(id);

  @override
  Future<void> upsertHabit(Habit habit) => _ds.upsert(habit);

  @override
  Future<void> deleteHabit(String id) => _ds.delete(id);

  @override
  Future<List<HabitCheckin>> getCheckins(String habitId) => _ds.fetchCheckins(habitId);

  @override
  Future<bool> isCheckedOn(String habitId, String date) => _ds.isCheckedOn(habitId, date);

  @override
  Future<void> checkin(String habitId, {required String date}) =>
      _ds.checkin(habitId, date: date);

  @override
  Future<void> uncheckin(String habitId, {required String date}) =>
      _ds.uncheckin(habitId, date: date);
}
