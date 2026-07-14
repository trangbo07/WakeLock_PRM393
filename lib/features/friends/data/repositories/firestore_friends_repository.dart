import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../profile/domain/entities/user_profile.dart';
import '../../domain/entities/friend.dart';
import '../../domain/repositories/friends_repository.dart';
import '../datasources/friends_firestore_datasource.dart';

/// Firestore-backed friends graph. Maps raw maps to entities and denormalizes
/// the caller's profile into request/friend documents.
class FirestoreFriendsRepository implements FriendsRepository {
  FirestoreFriendsRepository(this._ds);

  final FriendsFirestoreDataSource _ds;

  @override
  Stream<List<Friend>> watchFriends(String uid) =>
      _ds.watchFriends(uid).map((rows) => rows.map(_friendFromMap).toList());

  @override
  Stream<List<FriendRequest>> watchIncomingRequests(String uid) =>
      _ds.watchIncoming(uid).map((rows) => rows.map(_reqFromMap).toList());

  @override
  Future<List<UserProfile>> searchByUsername(String query,
      {required String excludeUid}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final rows = await _ds.searchByUsername(q);
    return rows
        .where((m) => m['uid'] != excludeUid)
        .map(_profileFromMap)
        .toList();
  }

  @override
  Future<void> sendRequest(
          {required UserProfile me,
          required String toUid,
          String message = ''}) =>
      _ds.addRequest({
        'from': me.uid,
        'to': toUid,
        'fromName': me.displayName,
        'fromUsername': me.username,
        'fromAvatarBase64': me.avatarBase64,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> acceptRequest(
          {required FriendRequest req, required UserProfile me}) =>
      _ds.accept(
        requestId: req.id,
        myUid: me.uid,
        myEntry: {
          'name': me.displayName,
          'username': me.username,
          'avatarBase64': me.avatarBase64,
          'streak': me.currentStreak,
        },
        otherUid: req.fromUid,
        otherEntry: {
          'name': req.fromName,
          'username': req.fromUsername,
          'avatarBase64': req.fromAvatarBase64,
          'streak': 0,
        },
      );

  @override
  Future<void> rejectRequest(String requestId) => _ds.deleteRequest(requestId);

  Friend _friendFromMap(Map<String, dynamic> m) => Friend(
        uid: m['uid'] as String,
        name: m['name'] as String? ?? '',
        username: m['username'] as String? ?? '',
        avatarBase64: m['avatarBase64'] as String?,
        avatarUrl: m['avatarUrl'] as String?,
        streak: (m['streak'] as num?)?.toInt() ?? 0,
      );

  FriendRequest _reqFromMap(Map<String, dynamic> m) => FriendRequest(
        id: m['id'] as String,
        fromUid: m['from'] as String? ?? '',
        fromName: m['fromName'] as String? ?? '',
        fromUsername: m['fromUsername'] as String? ?? '',
        fromAvatarBase64: m['fromAvatarBase64'] as String?,
        fromAvatarUrl: m['fromAvatarUrl'] as String?,
        message: m['message'] as String? ?? '',
      );

  UserProfile _profileFromMap(Map<String, dynamic> m) => UserProfile(
        uid: m['uid'] as String,
        username: m['username'] as String? ?? '',
        displayName: m['displayName'] as String? ?? '',
        bio: m['bio'] as String? ?? '',
        avatarBase64: m['avatarBase64'] as String?,
        avatarUrl: m['avatarUrl'] as String?,
        currentStreak: (m['currentStreak'] as num?)?.toInt() ?? 0,
        longestStreak: (m['longestStreak'] as num?)?.toInt() ?? 0,
        xp: (m['xp'] as num?)?.toInt() ?? 0,
        level: (m['level'] as num?)?.toInt() ?? 1,
        wakeRate: (m['wakeRate'] as num?)?.toDouble() ?? 0,
        photosShared: (m['photosShared'] as num?)?.toInt() ?? 0,
      );
}
