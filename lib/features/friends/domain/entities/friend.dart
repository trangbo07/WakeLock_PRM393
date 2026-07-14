import 'package:equatable/equatable.dart';

/// An accepted friend (denormalized entry under users/{uid}/friends/{friendUid}).
class Friend extends Equatable {
  const Friend({
    required this.uid,
    this.name = '',
    this.username = '',
    this.avatarBase64,
    this.streak = 0,
  });

  final String uid;
  final String name;
  final String username;
  final String? avatarBase64;
  final int streak;

  @override
  List<Object?> get props => [uid, name, username, avatarBase64, streak];
}

/// A pending incoming friend request (from `friend_requests`).
class FriendRequest extends Equatable {
  const FriendRequest({
    required this.id,
    required this.fromUid,
    this.fromName = '',
    this.fromUsername = '',
    this.fromAvatarBase64,
    this.message = '',
  });

  final String id;
  final String fromUid;
  final String fromName;
  final String fromUsername;
  final String? fromAvatarBase64;
  final String message;

  @override
  List<Object?> get props =>
      [id, fromUid, fromName, fromUsername, fromAvatarBase64, message];
}
