import 'package:cloud_firestore/cloud_firestore.dart';

/// Raw Firestore access for the feed (posts + comments + reactions).
class FeedFirestoreDataSource {
  FeedFirestoreDataSource([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _posts => _db.collection('posts');
  CollectionReference<Map<String, dynamic>> _comments(String id) =>
      _posts.doc(id).collection('comments');
  CollectionReference<Map<String, dynamic>> _reactions(String id) =>
      _posts.doc(id).collection('reactions');

  Stream<List<Map<String, dynamic>>> watchFeed() => _posts
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> watchComments(String postId) =>
      _comments(postId).orderBy('createdAt').snapshots().map(
          (s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Stream<List<Map<String, dynamic>>> watchReactors(String postId) =>
      _reactions(postId)
          .snapshots()
          .map((s) => s.docs.map((d) => {'uid': d.id, ...d.data()}).toList());

  Future<String?> myReaction(String postId, String uid) async {
    final doc = await _reactions(postId).doc(uid).get();
    return doc.data()?['emoji'] as String?;
  }

  Future<void> addComment(String postId, Map<String, dynamic> data) async {
    final batch = _db.batch();
    batch.set(_comments(postId).doc(), {
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_posts.doc(postId), {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }

  Future<void> setReaction(
      String postId, String uid, Map<String, dynamic> data) async {
    final ref = _reactions(postId).doc(uid);
    await _db.runTransaction((txn) async {
      final existed = (await txn.get(ref)).exists;
      txn.set(ref, data);
      if (!existed) {
        txn.update(_posts.doc(postId), {'reactionCount': FieldValue.increment(1)});
      }
    });
  }

  Future<void> removeReaction(String postId, String uid) async {
    final ref = _reactions(postId).doc(uid);
    await _db.runTransaction((txn) async {
      if ((await txn.get(ref)).exists) {
        txn.delete(ref);
        txn.update(
            _posts.doc(postId), {'reactionCount': FieldValue.increment(-1)});
      }
    });
  }

  Future<void> createPost(Map<String, dynamic> data) => _posts.add({
        ...data,
        'reactionCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
}
