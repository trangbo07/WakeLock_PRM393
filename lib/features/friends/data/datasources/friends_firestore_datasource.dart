import 'package:cloud_firestore/cloud_firestore.dart';

/// Raw Firestore access for the friends graph. Returns plain maps; the
/// repository maps to entities.
class FriendsFirestoreDataSource {
  FriendsFirestoreDataSource([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('friend_requests');
  CollectionReference<Map<String, dynamic>> _friendsOf(String uid) =>
      _users.doc(uid).collection('friends');

  Stream<List<Map<String, dynamic>>> watchFriends(String uid) => _friendsOf(uid)
      .snapshots()
      .map((s) => s.docs.map((d) => {'uid': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> watchIncoming(String uid) => _requests
      .where('to', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<List<Map<String, dynamic>>> searchByUsername(String q) async {
    // Prefix range [q, q+] → all usernames starting with q.
    final upper = '$q\u{F8FF}';
    final snap = await _users
        .where('username', isGreaterThanOrEqualTo: q)
        .where('username', isLessThanOrEqualTo: upper)
        .limit(20)
        .get();
    return snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
  }

  Future<void> addRequest(Map<String, dynamic> data) => _requests.add(data);

  /// Accept: write both friend entries and delete the request atomically.
  Future<void> accept({
    required String requestId,
    required String myUid,
    required Map<String, dynamic> myEntry,
    required String otherUid,
    required Map<String, dynamic> otherEntry,
  }) async {
    final batch = _db.batch();
    batch.set(_friendsOf(myUid).doc(otherUid), otherEntry);
    batch.set(_friendsOf(otherUid).doc(myUid), myEntry);
    batch.delete(_requests.doc(requestId));
    await batch.commit();
  }

  Future<void> deleteRequest(String id) => _requests.doc(id).delete();
}
