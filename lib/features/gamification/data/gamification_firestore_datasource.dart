import 'package:cloud_firestore/cloud_firestore.dart';

/// Coin/XP mutations on the `users/{uid}` doc for the shop and daily missions.
/// All done in transactions so balances never go negative or double-claim.
class GamificationFirestoreDataSource {
  GamificationFirestoreDataSource([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  /// Buy an item: deducts coins and adds it to ownedItems. Returns false if the
  /// user already owns it or can't afford it.
  Future<bool> purchase(String uid, String itemId, int price) {
    final ref = _user(uid);
    return _db.runTransaction<bool>((txn) async {
      final data = (await txn.get(ref)).data() ?? {};
      final coins = (data['coins'] as num?)?.toInt() ?? 0;
      final owned = (data['ownedItems'] as List?)?.cast<String>() ?? const [];
      if (owned.contains(itemId) || coins < price) return false;
      txn.update(ref, {
        'coins': coins - price,
        'ownedItems': FieldValue.arrayUnion([itemId]),
      });
      return true;
    });
  }

  /// Claim a daily mission: grants XP + coins once per [today] (yyyy-mm-dd).
  /// Returns false if already claimed today.
  Future<bool> claimMission(
    String uid,
    String missionId,
    int xp,
    int coins,
    String today,
  ) {
    final ref = _user(uid);
    return _db.runTransaction<bool>((txn) async {
      final data = (await txn.get(ref)).data() ?? {};
      final claims = (data['dailyClaims'] as Map?) ?? const {};
      if (claims[missionId] == today) return false;
      txn.update(ref, {
        'xp': FieldValue.increment(xp),
        'coins': FieldValue.increment(coins),
        'dailyClaims.$missionId': today,
      });
      return true;
    });
  }
}
