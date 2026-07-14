import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_firestore_datasource.dart';

/// Firestore-backed [ProfileRepository]. Maps between the `users/{uid}` doc
/// and [UserProfile] (mapping kept here, not in the entity).
class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository(this._ds);

  final ProfileFirestoreDataSource _ds;

  @override
  Stream<UserProfile?> watchProfile(String uid) =>
      _ds.watch(uid).map((m) => m == null ? null : _fromMap(uid, m));

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final m = await _ds.fetch(uid);
    return m == null ? null : _fromMap(uid, m);
  }

  @override
  Future<void> upsertProfile(UserProfile p) => _ds.upsert(p.uid, _toMap(p));

  @override
  Future<bool> reserveUsername(String username, String uid) =>
      _ds.reserveUsername(username, uid);

  @override
  Future<String> uploadAvatar(String uid, String filePath) =>
      _ds.uploadAvatar(uid, filePath);

  @override
  Future<void> updateProfileFields(
    String uid, {
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) {
    final data = <String, dynamic>{};
    if (username != null) data['username'] = username;
    if (displayName != null) data['displayName'] = displayName;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    if (bio != null) data['bio'] = bio;
    return _ds.upsert(uid, data);
  }

  UserProfile _fromMap(String uid, Map<String, dynamic> m) => UserProfile(
        uid: uid,
        username: m['username'] as String? ?? '',
        displayName: m['displayName'] as String? ?? '',
        bio: m['bio'] as String? ?? '',
        avatarUrl: m['avatarUrl'] as String?,
        currentStreak: (m['currentStreak'] as num?)?.toInt() ?? 0,
        longestStreak: (m['longestStreak'] as num?)?.toInt() ?? 0,
        xp: (m['xp'] as num?)?.toInt() ?? 0,
        level: (m['level'] as num?)?.toInt() ?? 1,
        wakeRate: (m['wakeRate'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> _toMap(UserProfile p) => {
        'username': p.username,
        'displayName': p.displayName,
        'bio': p.bio,
        'avatarUrl': p.avatarUrl,
        'currentStreak': p.currentStreak,
        'longestStreak': p.longestStreak,
        'xp': p.xp,
        'level': p.level,
        'wakeRate': p.wakeRate,
      };
}
