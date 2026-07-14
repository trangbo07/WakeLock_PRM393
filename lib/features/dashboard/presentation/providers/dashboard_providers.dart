import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../habit/presentation/providers/habit_providers.dart';
import '../../../streak/presentation/providers/streak_providers.dart';
import '../../domain/dashboard_stats.dart';

/// Aggregates wake_events + habit check-ins (read-only, no writes) into
/// dashboard numbers. Invalidate `wakeEventListProvider`/`habitListProvider`
/// to refresh.
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final events = await ref.watch(wakeEventListProvider.future);
  final habits = await ref.watch(habitListProvider.future);
  final habitRepo = ref.watch(habitRepositoryProvider);
  final checkinsPerHabit = await Future.wait(
    habits.map((h) => habitRepo.getCheckins(h.id)),
  );
  return DashboardCalculator().calculate(
    events: events,
    habits: habits,
    checkinsPerHabit: checkinsPerHabit,
  );
});
