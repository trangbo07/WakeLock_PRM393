import '../entities/user_profile.dart';

/// Profile contract, backed by Firestore `users/{uid}`.
abstract class ProfileRepository {
  Stream<UserProfile?> watchProfile(String uid);
  Future<UserProfile?> getProfile(String uid);

  /// Create or merge the profile doc.
  Future<void> upsertProfile(UserProfile profile);

  /// Claim a unique username. Returns false if already taken by another uid.
  Future<bool> reserveUsername(String username, String uid);

  /// Partial update — writes only the provided fields (won't reset stats).
  /// [avatarBase64] stores a small avatar inline (no Cloud Storage needed).
  Future<void> updateProfileFields(
    String uid, {
    String? username,
    String? displayName,
    String? avatarUrl,
    String? avatarBase64,
    String? bio,
  });
}
