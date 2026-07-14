import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/streak_calculator.dart';
import 'wake_event_providers.dart';

/// All wake events (used by streak/dashboard UI). Invalidate after any write
/// (fire/dismiss/snooze) to refresh dependents.
final wakeEventListProvider = FutureProvider((ref) => ref.watch(wakeEventRepositoryProvider).getAll());

/// Interface point exposed to Dev 2 (per docs/team-work-split.md): current /
/// longest streak + wake rate, computed from local `wake_events`. Dev 2 reads
/// this to sync `users/{uid}` for leaderboard/challenge features.
final streakProvider = FutureProvider<StreakStats>((ref) async {
  final events = await ref.watch(wakeEventListProvider.future);
  return StreakCalculator().calculate(events);
});
