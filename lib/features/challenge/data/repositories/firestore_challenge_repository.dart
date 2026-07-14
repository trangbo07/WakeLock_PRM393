import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/challenge.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../datasources/challenge_firestore_datasource.dart';

/// Firestore-backed challenges. Maps raw docs to entities and sorts client-side
/// (active first, then soonest-ending) to avoid a composite index.
class FirestoreChallengeRepository implements ChallengeRepository {
  FirestoreChallengeRepository(this._ds);

  final ChallengeFirestoreDataSource _ds;

  @override
  Stream<List<Challenge>> watchMyChallenges(String uid) =>
      _ds.watchMyChallenges(uid).map((rows) {
        final list = rows.map(_challenge).toList();
        list.sort((a, b) {
          if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
          final ae = a.endAt, be = b.endAt;
          if (ae == null || be == null) return 0;
          return a.isActive ? ae.compareTo(be) : be.compareTo(ae);
        });
        return list;
      });

  @override
  Stream<Challenge?> watchChallenge(String id) =>
      _ds.watchChallenge(id).map((m) => m == null ? null : _challenge(m));

  @override
  Stream<List<ChallengeParticipant>> watchParticipants(String id) =>
      _ds.watchParticipants(id).map((rows) => rows.map(_participant).toList());

  @override
  Future<String> createChallenge({
    required String title,
    required int days,
    required List<ChallengeParticipant> participants,
  }) {
    final now = DateTime.now();
    return _ds.createChallenge(
      {
        'title': title,
        'days': days,
        'createdBy': participants.isNotEmpty ? participants.first.uid : '',
        'startAt': Timestamp.fromDate(now),
        'endAt': Timestamp.fromDate(now.add(Duration(days: days))),
        'participantUids': participants.map((p) => p.uid).toList(),
      },
      participants
          .map((p) => {
                'uid': p.uid,
                'name': p.name,
                'username': p.username,
                'avatarUrl': p.avatarUrl,
                'avatarBase64': p.avatarBase64,
              })
          .toList(),
    );
  }

  @override
  Future<bool> checkIn(String challengeId, String uid) =>
      _ds.checkIn(challengeId, uid, DateTime.now());

  Challenge _challenge(Map<String, dynamic> m) => Challenge(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        days: (m['days'] as num?)?.toInt() ?? 7,
        createdBy: m['createdBy'] as String? ?? '',
        startAt: (m['startAt'] as Timestamp?)?.toDate(),
        endAt: (m['endAt'] as Timestamp?)?.toDate(),
        participantUids:
            (m['participantUids'] as List?)?.cast<String>() ?? const [],
      );

  ChallengeParticipant _participant(Map<String, dynamic> m) =>
      ChallengeParticipant(
        uid: m['uid'] as String,
        name: m['name'] as String? ?? '',
        username: m['username'] as String? ?? '',
        avatarUrl: m['avatarUrl'] as String?,
        avatarBase64: m['avatarBase64'] as String?,
        score: (m['score'] as num?)?.toInt() ?? 0,
        lastCheckIn: (m['lastCheckIn'] as Timestamp?)?.toDate(),
      );
}
