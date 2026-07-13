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
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.xp = 0,
    this.level = 1,
    this.wakeRate = 0,
  });

  final String uid;
  final String username;
  final String displayName;
  final String bio;
  final String? avatarUrl;
  final int currentStreak;
  final int longestStreak;
  final int xp;
  final int level;

  /// Wake-success rate 0..1 (synced from Dev 1's streak stats).
  final double wakeRate;

  UserProfile copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    int? currentStreak,
    int? longestStreak,
    int? xp,
    int? level,
    double? wakeRate,
  }) =>
      UserProfile(
        uid: uid,
        username: username ?? this.username,
        displayName: displayName ?? this.displayName,
        bio: bio ?? this.bio,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        xp: xp ?? this.xp,
        level: level ?? this.level,
        wakeRate: wakeRate ?? this.wakeRate,
      );

  @override
  List<Object?> get props => [
        uid,
        username,
        displayName,
        bio,
        avatarUrl,
        currentStreak,
        longestStreak,
        xp,
        level,
        wakeRate,
      ];
}
