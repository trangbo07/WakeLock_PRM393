import 'package:equatable/equatable.dart';

/// Public-ish user profile stored at Firestore `users/{uid}`. Denormalized
/// streak/xp fields let friends & leaderboards read a single doc.
class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    this.username = '',
    this.displayName = '',
    this.bio = '',
    this.avatarUrl,
    this.avatarBase64,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.xp = 0,
    this.level = 1,
    this.wakeRate = 0,
    this.photosShared = 0,
  });

  final String uid;
  final String username;
  final String displayName;
  final String bio;

  /// Remote avatar URL (e.g. from Google sign-in). May be null.
  final String? avatarUrl;

  /// Small avatar stored as base64 JPEG — avoids Cloud Storage (free plan).
  final String? avatarBase64;

  final int currentStreak;
  final int longestStreak;
  final int xp;
  final int level;

  /// Wake-success rate 0..1 (synced from Dev 1's streak stats).
  final double wakeRate;

  /// Number of morning photos shared (denormalized for the profile header).
  final int photosShared;

  UserProfile copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? avatarBase64,
    int? currentStreak,
    int? longestStreak,
    int? xp,
    int? level,
    double? wakeRate,
    int? photosShared,
  }) =>
      UserProfile(
        uid: uid,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        bio: bio ?? this.bio,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        avatarBase64: avatarBase64 ?? this.avatarBase64,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        xp: xp ?? this.xp,
        level: level ?? this.level,
        wakeRate: wakeRate ?? this.wakeRate,
        photosShared: photosShared ?? this.photosShared,
      );

  @override
  List<Object?> get props => [
        uid,
        username,
        displayName,
        bio,
        avatarUrl,
        avatarBase64,
        currentStreak,
        longestStreak,
        xp,
        level,
        wakeRate,
        photosShared,
      ];
}
