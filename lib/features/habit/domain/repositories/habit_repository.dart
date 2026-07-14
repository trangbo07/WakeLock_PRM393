import '../entities/habit.dart';

/// Persistence contract for habits + their check-ins.
abstract class HabitRepository {
  Future<List<Habit>> getHabits();
  Future<Habit?> getHabitById(String id);
  Future<void> upsertHabit(Habit habit);
  Future<void> deleteHabit(String id);

  /// All check-ins for [habitId], most recent first.
  Future<List<HabitCheckin>> getCheckins(String habitId);

  /// True if [habitId] already has a check-in for [date] ('YYYY-MM-DD').
  Future<bool> isCheckedOn(String habitId, String date);

  /// Record today's check-in. No-op if already checked in today (unique index).
  Future<void> checkin(String habitId, {required String date});

  /// Undo today's check-in (tapped again by mistake).
  Future<void> uncheckin(String habitId, {required String date});
}
