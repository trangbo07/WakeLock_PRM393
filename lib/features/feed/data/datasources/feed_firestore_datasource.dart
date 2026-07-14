import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../notifications/data/datasources/notifications_firestore_datasource.dart';

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
    await _notifyAuthor(
      postId,
      actorUid: data['uid'] as String?,
      type: 'comment',
      title: 'Bình luận mới',
      body: '${data['name'] ?? 'Ai đó'} đã bình luận: "${data['text'] ?? ''}"',
      actorName: data['name'] as String?,
      actorAvatarUrl: data['avatarUrl'] as String?,
      actorAvatarBase64: data['avatarBase64'] as String?,
    );
  }

  /// Notify a post's author of activity (skips notifying the actor about their
  /// own post). Best-effort.
  Future<void> _notifyAuthor(
    String postId, {
    required String? actorUid,
    required String type,
    required String title,
    required String body,
    String? actorName,
    String? actorAvatarUrl,
    String? actorAvatarBase64,
  }) async {
    final post = await _posts.doc(postId).get();
    final authorUid = post.data()?['authorUid'] as String?;
    if (authorUid == null || authorUid.isEmpty || authorUid == actorUid) return;
    await pushNotification(
      _db,
      authorUid,
      type: type,
      title: title,
      body: body,
      actorName: actorName,
      actorAvatarUrl: actorAvatarUrl,
      actorAvatarBase64: actorAvatarBase64,
    );
  }

  Future<void> setReaction(
      String postId, String uid, Map<String, dynamic> data) async {
    final ref = _reactions(postId).doc(uid);
    final isNew = await _db.runTransaction<bool>((txn) async {
      final existed = (await txn.get(ref)).exists;
      txn.set(ref, data);
      if (!existed) {
        txn.update(_posts.doc(postId), {'reactionCount': FieldValue.increment(1)});
      }
      return !existed;
    });
    // Only notify on a first-time reaction (not on emoji changes).
    if (isNew) {
      await _notifyAuthor(
        postId,
        actorUid: uid,
        type: 'reaction',
        title: 'Cảm xúc mới',
        body: '${data['name'] ?? 'Ai đó'} đã thả ${data['emoji'] ?? '❤️'} vào bài của bạn',
        actorName: data['name'] as String?,
        actorAvatarUrl: data['avatarUrl'] as String?,
        actorAvatarBase64: data['avatarBase64'] as String?,
      );
    }
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

  Future<String> createPost(Map<String, dynamic> data) async {
    final ref = await _posts.add({
      ...data,
      'reactionCount': 0,
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
