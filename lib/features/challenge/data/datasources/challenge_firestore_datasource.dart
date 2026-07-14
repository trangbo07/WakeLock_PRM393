import 'package:cloud_firestore/cloud_firestore.dart';

/// Raw Firestore access for challenges (`challenges/{id}` + `participants`).
class ChallengeFirestoreDataSource {
  ChallengeFirestoreDataSource([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _challenges =>
      _db.collection('challenges');
  CollectionReference<Map<String, dynamic>> _participants(String id) =>
      _challenges.doc(id).collection('participants');

  Stream<List<Map<String, dynamic>>> watchMyChallenges(String uid) =>
      _challenges
          .where('participantUids', arrayContains: uid)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<Map<String, dynamic>?> watchChallenge(String id) =>
      _challenges.doc(id).snapshots().map(
          (d) => d.exists ? {'id': d.id, ...?d.data()} : null);

  Stream<List<Map<String, dynamic>>> watchParticipants(String id) =>
      _participants(id)
          .orderBy('score', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => {'uid': d.id, ...d.data()}).toList());

  Future<String> createChallenge(
    Map<String, dynamic> data,
    List<Map<String, dynamic>> participants,
  ) async {
    final ref = _challenges.doc();
    final batch = _db.batch();
    batch.set(ref, data);
    for (final p in participants) {
      final uid = p['uid'] as String;
      batch.set(_participants(ref.id).doc(uid), {
        ...p..remove('uid'),
        'score': 0,
        'lastCheckIn': null,
      });
    }
    await batch.commit();
    return ref.id;
  }

  /// Transactionally bumps score once per calendar day. Returns false if the
  /// member already checked in today.
  Future<bool> checkIn(String challengeId, String uid, DateTime now) async {
    final ref = _participants(challengeId).doc(uid);
    return _db.runTransaction<bool>((txn) async {
      final snap = await txn.get(ref);
      final last = (snap.data()?['lastCheckIn'] as Timestamp?)?.toDate();
      if (last != null &&
          last.year == now.year &&
          last.month == now.month &&
          last.day == now.day) {
        return false;
      }
      txn.update(ref, {
        'score': FieldValue.increment(1),
        'lastCheckIn': Timestamp.fromDate(now),
      });
      return true;
    });
  }
}
