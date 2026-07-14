import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/challenge_firestore_datasource.dart';
import '../../data/repositories/firestore_challenge_repository.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/repositories/challenge_repository.dart';

final challengeDataSourceProvider = Provider<ChallengeFirestoreDataSource>(
  (ref) => ChallengeFirestoreDataSource(),
);

final challengeRepositoryProvider = Provider<ChallengeRepository>(
  (ref) => FirestoreChallengeRepository(ref.watch(challengeDataSourceProvider)),
);

/// Challenges the signed-in user takes part in (empty for guests).
final myChallengesProvider = StreamProvider<List<Challenge>>((ref) {
  final uid = ref.watch(sessionProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(challengeRepositoryProvider).watchMyChallenges(uid);
});

/// A single challenge doc (for the detail header).
final challengeProvider = StreamProvider.family<Challenge?, String>(
  (ref, id) => ref.watch(challengeRepositoryProvider).watchChallenge(id),
);

/// Leaderboard: participants ordered by score.
final challengeParticipantsProvider =
    StreamProvider.family<List<ChallengeParticipant>, String>(
  (ref, id) => ref.watch(challengeRepositoryProvider).watchParticipants(id),
);
