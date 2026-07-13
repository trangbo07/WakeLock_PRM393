import '../entities/user_profile.dart';

/// Profile contract, backed by Firestore `users/{uid}`.
abstract class ProfileRepository {
  Stream<UserProfile?> watchProfile(String uid);
  Future<UserProfile?> getProfile(String uid);

  /// Create or merge the profile doc.
  Future<void> upsertProfile(UserProfile profile);
}
