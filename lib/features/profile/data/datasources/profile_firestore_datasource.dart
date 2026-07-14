import 'package:cloud_firestore/cloud_firestore.dart';

/// Raw Firestore access for `users/{uid}`. Returns plain maps; the repository
/// maps to/from [UserProfile]. This is the Firestore template for Dev 2.
class ProfileFirestoreDataSource {
  ProfileFirestoreDataSource([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _usernames =>
      _db.collection('usernames');

  Stream<Map<String, dynamic>?> watch(String uid) =>
      _users.doc(uid).snapshots().map((d) => d.data());

  Future<Map<String, dynamic>?> fetch(String uid) async =>
      (await _users.doc(uid).get()).data();

  Future<void> upsert(String uid, Map<String, dynamic> data) =>
      _users.doc(uid).set(data, SetOptions(merge: true));

  /// Atomically claim [username] for [uid]. Returns false if another uid owns it.
  /// `usernames/{username}` is the uniqueness index (doc id = the username).
  Future<bool> reserveUsername(String username, String uid) {
    final ref = _usernames.doc(username);
    return _db.runTransaction<bool>((txn) async {
      final snap = await txn.get(ref);
      if (snap.exists && snap.data()?['uid'] != uid) return false;
      txn.set(ref, {'uid': uid});
      return true;
    });
  }
}
