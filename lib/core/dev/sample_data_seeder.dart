import 'package:cloud_firestore/cloud_firestore.dart';

/// Dev-only Firestore seeder: creates a set of sample users (with varied
/// streak/level/wake-rate), makes some of them the current user's friends, and
/// leaves a couple of pending friend requests. Requires the DEV Firestore rules
/// (authenticated read/write all). Safe to run repeatedly (idempotent merges).
class SampleDataSeeder {
  SampleDataSeeder([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const List<Map<String, dynamic>> people = [
    {'uid': 'seed_linh', 'username': 'linh', 'name': 'Linh', 'bio': 'Chăm chỉ mỗi ngày', 'streak': 28, 'longest': 30, 'xp': 1200, 'level': 5, 'wake': 0.95},
    {'uid': 'seed_nam', 'username': 'nam', 'name': 'Nam', 'bio': 'Dậy sớm cùng nhau', 'streak': 18, 'longest': 22, 'xp': 820, 'level': 4, 'wake': 0.88},
    {'uid': 'seed_quan', 'username': 'quan', 'name': 'Quân', 'bio': 'Không snooze!', 'streak': 15, 'longest': 15, 'xp': 600, 'level': 3, 'wake': 0.80},
    {'uid': 'seed_phuong', 'username': 'phuong', 'name': 'Phương', 'bio': '', 'streak': 12, 'longest': 20, 'xp': 540, 'level': 3, 'wake': 0.77},
    {'uid': 'seed_khoa', 'username': 'khoa', 'name': 'Khoa', 'bio': '', 'streak': 9, 'longest': 12, 'xp': 300, 'level': 2, 'wake': 0.70},
    {'uid': 'seed_minhanh', 'username': 'minhanh', 'name': 'Minh Anh', 'bio': 'Người mới', 'streak': 5, 'longest': 8, 'xp': 150, 'level': 2, 'wake': 0.60},
    {'uid': 'seed_trang', 'username': 'trang', 'name': 'Trang', 'bio': '', 'streak': 3, 'longest': 10, 'xp': 90, 'level': 1, 'wake': 0.55},
    {'uid': 'seed_hoang', 'username': 'hoang', 'name': 'Hoàng', 'bio': '', 'streak': 1, 'longest': 7, 'xp': 40, 'level': 1, 'wake': 0.50},
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
          'currentStreak': p['streak'],
          'longestStreak': p['longest'],
          'xp': p['xp'],
          'level': p['level'],
          'wakeRate': p['wake'],
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
        'streak': p['streak'],
      });
      friends.set(
        _db.collection('users').doc(uid).collection('friends').doc(myUid),
        {'name': myName, 'username': myUsername, 'streak': 0},
      );
    }
    await friends.commit();

    // 3) Two pending friend requests TO me.
    for (final p in people.skip(4).take(2)) {
      await _db.collection('friend_requests').add({
        'from': p['uid'],
        'to': myUid,
        'fromName': p['name'],
        'fromUsername': p['username'],
        'message': 'Mình muốn kết bạn với bạn trên WakeLock!',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
