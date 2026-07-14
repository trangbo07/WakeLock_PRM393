import '../entities/post.dart';

/// Feed of morning-photo posts + their comments and reactions (Firestore).
abstract class FeedRepository {
  Stream<List<Post>> watchFeed();
  Stream<List<Comment>> watchComments(String postId);
  Stream<List<Reactor>> watchReactors(String postId);

  Future<String?> myReaction(String postId, String uid);

  Future<void> addComment(
    String postId, {
    required String uid,
    required String name,
    String? avatarUrl,
    String? avatarBase64,
    required String text,
  });

  /// Set (or change) the current user's reaction emoji on a post.
  Future<void> setReaction(
    String postId, {
    required String uid,
    required String emoji,
    required String name,
    String? avatarUrl,
    String? avatarBase64,
  });

  Future<void> removeReaction(String postId, String uid);

  /// Returns the new post's id.
  Future<String> createPost({
    required String authorUid,
    required String authorName,
    String authorUsername,
    String? authorAvatarUrl,
    String? authorAvatarBase64,
    String? photoUrl,
    String? photoBase64,
    String caption,
  });
}
