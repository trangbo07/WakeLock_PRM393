import 'package:cloud_firestore/cloud_firestore.dart';

/// Dev-only Firestore seeder: creates a set of sample users (varied
/// streak/level/wake-rate + avatar), makes some the current user's friends, and
/// leaves a couple of pending friend requests. Requires the DEV Firestore rules
/// (authenticated read/write all). Idempotent (merges).
class SampleDataSeeder {
  SampleDataSeeder([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // Avatars use pravatar.cc (real placeholder photos, loaded over network).
  static const List<Map<String, dynamic>> people = [
    {'uid': 'seed_linh', 'username': 'linh', 'name': 'Linh', 'bio': 'Chăm chỉ mỗi ngày 💪', 'streak': 28, 'longest': 30, 'xp': 1200, 'level': 5, 'wake': 0.95, 'photos': 156, 'avatar': 'https://i.pravatar.cc/150?img=5'},
    {'uid': 'seed_nam', 'username': 'nam', 'name': 'Nam', 'bio': 'Dậy sớm cùng nhau', 'streak': 18, 'longest': 22, 'xp': 820, 'level': 4, 'wake': 0.88, 'photos': 98, 'avatar': 'https://i.pravatar.cc/150?img=12'},
    {'uid': 'seed_quan', 'username': 'quan', 'name': 'Quân', 'bio': 'Không snooze!', 'streak': 15, 'longest': 15, 'xp': 600, 'level': 3, 'wake': 0.80, 'photos': 72, 'avatar': 'https://i.pravatar.cc/150?img=15'},
    {'uid': 'seed_phuong', 'username': 'phuong', 'name': 'Phương', 'bio': 'Yêu buổi sáng', 'streak': 12, 'longest': 20, 'xp': 540, 'level': 3, 'wake': 0.77, 'photos': 60, 'avatar': 'https://i.pravatar.cc/150?img=45'},
    {'uid': 'seed_khoa', 'username': 'khoa', 'name': 'Khoa', 'bio': 'Cà phê là chân ái', 'streak': 9, 'longest': 12, 'xp': 300, 'level': 2, 'wake': 0.70, 'photos': 34, 'avatar': 'https://i.pravatar.cc/150?img=33'},
    {'uid': 'seed_minhanh', 'username': 'minhanh', 'name': 'Minh Anh', 'bio': 'Người mới', 'streak': 5, 'longest': 8, 'xp': 150, 'level': 2, 'wake': 0.60, 'photos': 18, 'avatar': 'https://i.pravatar.cc/150?img=47'},
    {'uid': 'seed_trang', 'username': 'trang', 'name': 'Trang', 'bio': 'Cố gắng lên!', 'streak': 3, 'longest': 10, 'xp': 90, 'level': 1, 'wake': 0.55, 'photos': 9, 'avatar': 'https://i.pravatar.cc/150?img=20'},
    {'uid': 'seed_hoang', 'username': 'hoang', 'name': 'Hoàng', 'bio': '', 'streak': 1, 'longest': 7, 'xp': 40, 'level': 1, 'wake': 0.50, 'photos': 3, 'avatar': 'https://i.pravatar.cc/150?img=68'},
  ];

  Future<void> seed({
    required String myUid,
    required String myName,
    required String myUsername,
  }) async {
    // 1) Sample user profiles + username index.
    final users = _db.batch();
    for (final p in people) {
      final uid = p['uid'] as String;
      users.set(
        _db.collection('users').doc(uid),
        {
          'username': p['username'],
          'displayName': p['name'],
          'bio': p['bio'],
          'avatarUrl': p['avatar'],
          'currentStreak': p['streak'],
          'longestStreak': p['longest'],
          'xp': p['xp'],
          'level': p['level'],
          'wakeRate': p['wake'],
          'photosShared': p['photos'],
        },
        SetOptions(merge: true),
      );
      users.set(_db.collection('usernames').doc(p['username'] as String),
          {'uid': uid});
    }
    await users.commit();

    // 2) First 4 become my friends (both directions).
    final friends = _db.batch();
    final myFriends = _db.collection('users').doc(myUid).collection('friends');
    for (final p in people.take(4)) {
      final uid = p['uid'] as String;
      friends.set(myFriends.doc(uid), {
        'name': p['name'],
        'username': p['username'],
        'avatarUrl': p['avatar'],
        'streak': p['streak'],
      });
      friends.set(
        _db.collection('users').doc(uid).collection('friends').doc(myUid),
        {'name': myName, 'username': myUsername, 'streak': 0},
      );
    }
    await friends.commit();

    // 3) Clear previous seed requests to me (idempotent), then add 2 fresh.
    final existing = await _db
        .collection('friend_requests')
        .where('to', isEqualTo: myUid)
        .get();
    final clear = _db.batch();
    for (final doc in existing.docs) {
      if ((doc.data()['from'] as String?)?.startsWith('seed_') ?? false) {
        clear.delete(doc.reference);
      }
    }
    await clear.commit();
    for (final p in people.skip(4).take(2)) {
      await _db.collection('friend_requests').add({
        'from': p['uid'],
        'to': myUid,
        'fromName': p['name'],
        'fromUsername': p['username'],
        'fromAvatarUrl': p['avatar'],
        'message': 'Mình muốn kết bạn với bạn trên WakeLock!',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Remove all seeded artifacts: seed users + username index, my friend
  /// entries pointing at seed users, and any friend requests from seed users.
  Future<void> clearSeed({required String myUid}) async {
    // Friend requests to me from seed users.
    final reqs = await _db
        .collection('friend_requests')
        .where('to', isEqualTo: myUid)
        .get();
    final b1 = _db.batch();
    for (final d in reqs.docs) {
      if ((d.data()['from'] as String?)?.startsWith('seed_') ?? false) {
        b1.delete(d.reference);
      }
    }
    await b1.commit();

    // My friend entries that point at seed users.
    final mine =
        await _db.collection('users').doc(myUid).collection('friends').get();
    final b2 = _db.batch();
    for (final d in mine.docs) {
      if (d.id.startsWith('seed_')) b2.delete(d.reference);
    }
    await b2.commit();

    // Seed user docs + username index + their reciprocal friend entry.
    final b3 = _db.batch();
    for (final p in people) {
      final uid = p['uid'] as String;
      b3.delete(_db.collection('users').doc(uid));
      b3.delete(_db.collection('usernames').doc(p['username'] as String));
      b3.delete(
          _db.collection('users').doc(uid).collection('friends').doc(myUid));
    }
    await b3.commit();
  }
}
