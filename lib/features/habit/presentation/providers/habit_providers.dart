import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/habit_local_datasource.dart';
import '../../data/repositories/local_habit_repository.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';

final habitLocalDataSourceProvider = Provider<HabitLocalDataSource>(
  (ref) => HabitLocalDataSource(ref.watch(appDatabaseProvider)),
);

final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => LocalHabitRepository(ref.watch(habitLocalDataSourceProvider)),
);

/// All habits (newest first). Invalidate after create/edit/delete/check-in.
final habitListProvider = FutureProvider<List<Habit>>(
  (ref) => ref.watch(habitRepositoryProvider).getHabits(),
);

/// Check-ins for one habit, newest first.
final habitCheckinsProvider =
    FutureProvider.family<List<HabitCheckin>, String>(
  (ref, habitId) => ref.watch(habitRepositoryProvider).getCheckins(habitId),
);

/// 'YYYY-MM-DD' key for "today" in local time — the day boundary used
/// everywhere check-ins are recorded/queried.
String todayDateKey() {
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)}';
}
