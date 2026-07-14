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

  /// Sample morning-photo posts. Authors are among the first 4 (my friends) so
  /// the "Bạn bè" tab is populated. Photos load from picsum (network).
  static const List<Map<String, dynamic>> posts = [
    {'author': 'seed_linh', 'caption': 'Chào buổi sáng! Dậy lúc 5:30 ☀️', 'reactors': ['seed_nam', 'seed_quan', 'seed_phuong'], 'comments': [{'uid': 'seed_nam', 'text': 'Đỉnh quá! 🔥'}, {'uid': 'seed_phuong', 'text': 'Ghen tị ghê 😍'}]},
    {'author': 'seed_nam', 'caption': 'Cà phê và bình minh ☕', 'reactors': ['seed_linh', 'seed_khoa'], 'comments': [{'uid': 'seed_linh', 'text': 'Nhìn ngon thế 😋'}]},
    {'author': 'seed_quan', 'caption': 'Chạy bộ 5km xong, sảng khoái 🏃', 'reactors': ['seed_linh', 'seed_nam', 'seed_phuong', 'seed_khoa'], 'comments': [{'uid': 'seed_quan', 'text': 'Ai chạy cùng mai không?'}]},
    {'author': 'seed_phuong', 'caption': 'Thiền 10 phút đầu ngày 🧘‍♀️', 'reactors': ['seed_linh'], 'comments': []},
    {'author': 'seed_linh', 'caption': 'Không snooze hôm nay 💪', 'reactors': ['seed_nam', 'seed_quan'], 'comments': [{'uid': 'seed_khoa', 'text': 'Quá xịn 👏'}]},
    {'author': 'seed_khoa', 'caption': 'Trời đẹp quá, dậy sớm thật đáng!', 'reactors': ['seed_phuong', 'seed_linh'], 'comments': []},
  ];

  static const List<String> _reactEmojis = ['❤️', '🔥', '💪', '😍', '😮', '😂'];

  Map<String, dynamic> _person(String uid) =>
      people.firstWhere((p) => p['uid'] == uid);

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

    // 4) Sample feed posts + their reactions/comments. Deterministic doc ids
    // ('seed_post_i', reactor uid, 'seed_c_j') keep re-runs idempotent.
    final now = DateTime.now();
    final feed = _db.batch();
    for (var i = 0; i < posts.length; i++) {
      final post = posts[i];
      final author = _person(post['author'] as String);
      final reactors = (post['reactors'] as List).cast<String>();
      final comments = (post['comments'] as List).cast<Map<String, dynamic>>();
      final ref = _db.collection('posts').doc('seed_post_$i');

      feed.set(ref, {
        'authorUid': author['uid'],
        'authorName': author['name'],
        'authorUsername': author['username'],
        'authorAvatarUrl': author['avatar'],
        'photoUrl': 'https://picsum.photos/seed/wl_post_$i/600/600',
        'caption': post['caption'],
        'reactionCount': reactors.length,
        'commentCount': comments.length,
        // Stagger timestamps so the feed has a sensible newest-first order.
        'createdAt': Timestamp.fromDate(now.subtract(Duration(minutes: i * 47))),
      });

      for (var r = 0; r < reactors.length; r++) {
        final person = _person(reactors[r]);
        feed.set(ref.collection('reactions').doc(reactors[r]), {
          'name': person['name'],
          'avatarUrl': person['avatar'],
          'emoji': _reactEmojis[r % _reactEmojis.length],
        });
      }
      for (var c = 0; c < comments.length; c++) {
        final person = _person(comments[c]['uid'] as String);
        feed.set(ref.collection('comments').doc('seed_c_$c'), {
          'uid': person['uid'],
          'name': person['name'],
          'avatarUrl': person['avatar'],
          'text': comments[c]['text'],
          'createdAt':
              Timestamp.fromDate(now.subtract(Duration(minutes: i * 47 - c))),
        });
      }
    }
    await feed.commit();

    // 5) Sample challenges: one active (I can check in), one already ended.
    final challengeSeeds = [
      {
        'id': 'seed_challenge_0',
        'title': 'Thử thách dậy sớm 7 ngày',
        'days': 7,
        'start': now.subtract(const Duration(days: 2)),
        'end': now.add(const Duration(days: 5)),
        'scores': {'seed_linh': 6, 'seed_nam': 5, myUid: 4, 'seed_quan': 3},
      },
      {
        'id': 'seed_challenge_1',
        'title': 'Cuối tuần không ngủ nướng',
        'days': 3,
        'start': now.subtract(const Duration(days: 5)),
        'end': now.subtract(const Duration(days: 2)),
        'scores': {'seed_linh': 3, myUid: 2, 'seed_phuong': 1},
      },
    ];
    final ch = _db.batch();
    for (final c in challengeSeeds) {
      final scores = c['scores'] as Map<String, int>;
      final ref = _db.collection('challenges').doc(c['id'] as String);
      ch.set(ref, {
        'title': c['title'],
        'days': c['days'],
        'createdBy': myUid,
        'startAt': Timestamp.fromDate(c['start'] as DateTime),
        'endAt': Timestamp.fromDate(c['end'] as DateTime),
        'participantUids': scores.keys.toList(),
      });
      scores.forEach((uid, score) {
        final isMe = uid == myUid;
        final person = isMe ? null : _person(uid);
        ch.set(ref.collection('participants').doc(uid), {
          'name': isMe ? myName : person!['name'],
          'username': isMe ? myUsername : person!['username'],
          'avatarUrl': isMe ? null : person!['avatar'],
          'score': score,
          // Friends checked in yesterday; leave mine null so I can check in.
          'lastCheckIn': isMe
              ? null
              : Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        });
      });
    }
    await ch.commit();
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

    // Seed posts + their reactions/comments subcollections.
    for (var i = 0; i < posts.length; i++) {
      final ref = _db.collection('posts').doc('seed_post_$i');
      for (final sub in ['reactions', 'comments']) {
        final docs = await ref.collection(sub).get();
        final b = _db.batch();
        for (final d in docs.docs) {
          b.delete(d.reference);
        }
        await b.commit();
      }
      await ref.delete();
    }

    // Seed challenges + their participants subcollection.
    for (final id in ['seed_challenge_0', 'seed_challenge_1']) {
      final ref = _db.collection('challenges').doc(id);
      final parts = await ref.collection('participants').get();
      final b = _db.batch();
      for (final d in parts.docs) {
        b.delete(d.reference);
      }
      await b.commit();
      await ref.delete();
    }
  }
}
