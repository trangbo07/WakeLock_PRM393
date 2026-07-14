import 'package:equatable/equatable.dart';

/// A social notification (`users/{uid}/notifications/{id}`), created by real
/// events: friend requests/accepts, reactions and comments on your posts.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    this.type = 'system',
    this.title = '',
    this.body = '',
    this.actorName,
    this.actorAvatarUrl,
    this.actorAvatarBase64,
    this.read = false,
    this.createdAt,
  });

  final String id;

  /// friend_request | friend_accept | reaction | comment | system
  final String type;
  final String title;
  final String body;
  final String? actorName;
  final String? actorAvatarUrl;
  final String? actorAvatarBase64;
  final bool read;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [id, type, title, body, actorName, actorAvatarUrl, actorAvatarBase64, read, createdAt];
}
