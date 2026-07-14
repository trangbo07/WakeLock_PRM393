import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/post.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_firestore_datasource.dart';

/// Firestore-backed feed. Maps raw docs to entities.
class FirestoreFeedRepository implements FeedRepository {
  FirestoreFeedRepository(this._ds);

  final FeedFirestoreDataSource _ds;

  @override
  Stream<List<Post>> watchFeed() =>
      _ds.watchFeed().map((rows) => rows.map(_post).toList());

  @override
  Stream<List<Comment>> watchComments(String postId) =>
      _ds.watchComments(postId).map((rows) => rows.map(_comment).toList());

  @override
  Stream<List<Reactor>> watchReactors(String postId) =>
      _ds.watchReactors(postId).map((rows) => rows.map(_reactor).toList());

  @override
  Future<String?> myReaction(String postId, String uid) =>
      _ds.myReaction(postId, uid);

  @override
  Future<void> addComment(
    String postId, {
    required String uid,
    required String name,
    String? avatarUrl,
    String? avatarBase64,
    required String text,
  }) =>
      _ds.addComment(postId, {
        'uid': uid,
        'name': name,
        'avatarUrl': avatarUrl,
        'avatarBase64': avatarBase64,
        'text': text,
      });

  @override
  Future<void> setReaction(
    String postId, {
    required String uid,
    required String emoji,
    required String name,
    String? avatarUrl,
    String? avatarBase64,
  }) =>
      _ds.setReaction(postId, uid, {
        'emoji': emoji,
        'name': name,
        'avatarUrl': avatarUrl,
        'avatarBase64': avatarBase64,
      });

  @override
  Future<void> removeReaction(String postId, String uid) =>
      _ds.removeReaction(postId, uid);

  @override
  Future<String> createPost({
    required String authorUid,
    required String authorName,
    String authorUsername = '',
    String? authorAvatarUrl,
    String? authorAvatarBase64,
    String? photoUrl,
    String? photoBase64,
    String caption = '',
  }) =>
      _ds.createPost({
        'authorUid': authorUid,
        'authorName': authorName,
        'authorUsername': authorUsername,
        'authorAvatarUrl': authorAvatarUrl,
        'authorAvatarBase64': authorAvatarBase64,
        'photoUrl': photoUrl,
        'photoBase64': photoBase64,
        'caption': caption,
      });

  Post _post(Map<String, dynamic> m) => Post(
        id: m['id'] as String,
        authorUid: m['authorUid'] as String? ?? '',
        authorName: m['authorName'] as String? ?? '',
        authorUsername: m['authorUsername'] as String? ?? '',
        authorAvatarUrl: m['authorAvatarUrl'] as String?,
        authorAvatarBase64: m['authorAvatarBase64'] as String?,
        photoUrl: m['photoUrl'] as String?,
        photoBase64: m['photoBase64'] as String?,
        caption: m['caption'] as String? ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
        reactionCount: (m['reactionCount'] as num?)?.toInt() ?? 0,
        commentCount: (m['commentCount'] as num?)?.toInt() ?? 0,
      );

  Comment _comment(Map<String, dynamic> m) => Comment(
        id: m['id'] as String,
        uid: m['uid'] as String? ?? '',
        name: m['name'] as String? ?? '',
        avatarUrl: m['avatarUrl'] as String?,
        avatarBase64: m['avatarBase64'] as String?,
        text: m['text'] as String? ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );

  Reactor _reactor(Map<String, dynamic> m) => Reactor(
        uid: m['uid'] as String,
        name: m['name'] as String? ?? '',
        avatarUrl: m['avatarUrl'] as String?,
        avatarBase64: m['avatarBase64'] as String?,
        emoji: m['emoji'] as String? ?? '❤️',
      );
}
