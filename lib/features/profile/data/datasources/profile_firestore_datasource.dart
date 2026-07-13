import 'package:cloud_firestore/cloud_firestore.dart';

/// Raw Firestore access for `users/{uid}`. Returns plain maps; the repository
/// maps to/from [UserProfile]. This is the Firestore template for Dev 2.
class ProfileFirestoreDataSource {
  ProfileFirestoreDataSource([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  Stream<Map<String, dynamic>?> watch(String uid) =>
      _users.doc(uid).snapshots().map((d) => d.data());

  Future<Map<String, dynamic>?> fetch(String uid) async =>
      (await _users.doc(uid).get()).data();

  Future<void> upsert(String uid, Map<String, dynamic> data) =>
      _users.doc(uid).set(data, SetOptions(merge: true));
}
