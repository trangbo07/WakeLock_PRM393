import '../../../profile/domain/entities/user_profile.dart';
import '../entities/friend.dart';

/// Friends graph over Firestore (`friend_requests` + users/{uid}/friends).
abstract class FriendsRepository {
  Stream<List<Friend>> watchFriends(String uid);
  Stream<List<FriendRequest>> watchIncomingRequests(String uid);

  /// Prefix search on username (excludes [excludeUid], typically the caller).
  Future<List<UserProfile>> searchByUsername(String query,
      {required String excludeUid});

  Future<void> sendRequest(
      {required UserProfile me, required String toUid, String message});
  Future<void> acceptRequest({required FriendRequest req, required UserProfile me});
  Future<void> rejectRequest(String requestId);
}
