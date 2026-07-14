import 'package:equatable/equatable.dart';

/// A morning-photo post in the feed (`posts/{id}`).
class Post extends Equatable {
  const Post({
    required this.id,
    required this.authorUid,
    this.authorName = '',
    this.authorUsername = '',
    this.authorAvatarUrl,
    this.authorAvatarBase64,
    this.photoUrl,
    this.photoBase64,
    this.caption = '',
    this.createdAt,
    this.reactionCount = 0,
    this.commentCount = 0,
    this.myReaction,
  });

  final String id;
  final String authorUid;
  final String authorName;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String? authorAvatarBase64;
  final String? photoUrl;
  final String? photoBase64;
  final String caption;
  final DateTime? createdAt;
  final int reactionCount;
  final int commentCount;

  /// The current user's reaction emoji on this post, if any (client-side).
  final String? myReaction;

  Post copyWith({String? myReaction, int? reactionCount, int? commentCount}) =>
      Post(
        id: id,
        authorUid: authorUid,
        authorName: authorName,
        authorUsername: authorUsername,
        authorAvatarUrl: authorAvatarUrl,
        authorAvatarBase64: authorAvatarBase64,
        photoUrl: photoUrl,
        photoBase64: photoBase64,
        caption: caption,
        createdAt: createdAt,
        reactionCount: reactionCount ?? this.reactionCount,
        commentCount: commentCount ?? this.commentCount,
        myReaction: myReaction ?? this.myReaction,
      );

  @override
  List<Object?> get props => [
        id,
        authorUid,
        authorName,
        authorUsername,
        authorAvatarUrl,
        authorAvatarBase64,
        photoUrl,
        photoBase64,
        caption,
        createdAt,
        reactionCount,
        commentCount,
        myReaction,
      ];
}

/// A comment on a post (`posts/{id}/comments/{id}`).
class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.uid,
    this.name = '',
    this.avatarUrl,
    this.avatarBase64,
    this.text = '',
    this.createdAt,
  });

  final String id;
  final String uid;
  final String name;
  final String? avatarUrl;
  final String? avatarBase64;
  final String text;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [id, uid, name, avatarUrl, avatarBase64, text, createdAt];
}

/// One person's reaction on a post (`posts/{id}/reactions/{uid}`).
class Reactor extends Equatable {
  const Reactor({
    required this.uid,
    this.name = '',
    this.avatarUrl,
    this.avatarBase64,
    this.emoji = '❤️',
  });

  final String uid;
  final String name;
  final String? avatarUrl;
  final String? avatarBase64;
  final String emoji;

  @override
  List<Object?> get props => [uid, name, avatarUrl, avatarBase64, emoji];
}
