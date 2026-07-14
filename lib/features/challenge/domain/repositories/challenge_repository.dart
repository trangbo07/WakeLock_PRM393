import '../entities/challenge.dart';

/// Friend wake-up challenges backed by Firestore.
abstract class ChallengeRepository {
  /// Challenges the user takes part in (newest first, client-sorted).
  Stream<List<Challenge>> watchMyChallenges(String uid);

  Stream<Challenge?> watchChallenge(String id);

  /// Participants of a challenge, highest score first.
  Stream<List<ChallengeParticipant>> watchParticipants(String id);

  /// Create a challenge and seed its participants (score 0). Returns the id.
  Future<String> createChallenge({
    required String title,
    required int days,
    required List<ChallengeParticipant> participants,
  });

  /// Log today's wake-up for [uid]. Returns false if already checked in today.
  Future<bool> checkIn(String challengeId, String uid);
}
