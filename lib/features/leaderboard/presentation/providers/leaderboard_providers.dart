import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../friends/presentation/providers/friends_providers.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// Me + my friends' profiles for the leaderboard. Ranking (by metric) is done
/// client-side on the page. Empty for guests.
final leaderboardProvider =
    FutureProvider.autoDispose<List<UserProfile>>((ref) async {
  final uid = ref.watch(sessionProvider).asData?.value?.uid;
  if (uid == null) return const [];
  final repo = ref.watch(profileRepositoryProvider);
  final friends = ref.watch(friendsListProvider).asData?.value ?? const [];
  final uids = <String>{uid, ...friends.map((f) => f.uid)};
  final results = await Future.wait(uids.map(repo.getProfile));
  return results.whereType<UserProfile>().toList();
});
