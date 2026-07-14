import 'package:cloud_firestore/cloud_firestore.dart';

import 'demo_people.dart';

/// Dev/demo Firestore seeder: creates 50 sample users (varied
/// streak/level/wake-rate + avatar), makes 30 of them the current user's
/// friends, leaves a few pending requests, and fills the feed, challenges and
/// notifications. Also boosts the current ("hero") user so every screen —
/// profile, gamification, leaderboard — looks fully populated for a marketing
/// demo. Requires permissive (dev/test) Firestore rules. Idempotent (fixed ids
/// + merge).
class SampleDataSeeder {
  SampleDataSeeder([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  final List<DemoPerson> _people = buildDemoPeople();

  static const int _friendCount = 30; // how many of the 50 befriend the hero
  static const int _requestCount = 5; // pending friend requests to the hero
  static const int _postCount = 18; // seeded feed posts
  static const int _notifCount = 6; // seeded notifications in the hero's inbox

  Future<void> seed({
    required String myUid,
    required String myName,
    required String myUsername,
  }) async {
    // 0) Hero stats — high enough to unlock every achievement (longest≥30,
    // photos≥50, xp≥3000) and show a rich profile/leaderboard/gamification.
    await _db.collection('users').doc(myUid).set({
      'username': myUsername,
      'displayName': myName,
      'currentStreak': 26,
      'longestStreak': 30,
      'xp': 3200,
      'level': 3200 ~/ 500 + 1,
      'wakeRate': 0.9,
      'photosShared': 60,
      'coins': 2000,
      'ownedItems': ['theme_galaxy', 'frame_gold'],
      'dailyClaims': <String, String>{},
    }, SetOptions(merge: true));
    // Keep the username index in sync so the hero is searchable.
    if (myUsername.isNotEmpty) {
      await _db.collection('usernames').doc(myUsername).set({'uid': myUid});
    }

    // 1) 50 sample user profiles + username index.
    final users = _db.batch();
    for (final p in _people) {
      users.set(
        _db.collection('users').doc(p.uid),
        {
          'username': p.username,
          'displayName': p.name,
          'bio': p.bio,
          'avatarUrl': p.avatar,
          'currentStreak': p.streak,
          'longestStreak': p.longest,
          'xp': p.xp,
          'level': p.level,
          'wakeRate': p.wake,
          'photosShared': p.photos,
          'coins': p.coins,
          'ownedItems': <String>[],
          'dailyClaims': <String, String>{},
        },
        SetOptions(merge: true),
      );
      users.set(_db.collection('usernames').doc(p.username), {'uid': p.uid});
    }
    await users.commit();

    // 2) First [_friendCount] people become the hero's friends (both ways).
    final friends = _db.batch();
    final myFriends = _db.collection('users').doc(myUid).collection('friends');
    for (final p in _people.take(_friendCount)) {
      friends.set(myFriends.doc(p.uid), {
        'name': p.name,
        'username': p.username,
        'avatarUrl': p.avatar,
        'streak': p.streak,
      });
      friends.set(
        _db.collection('users').doc(p.uid).collection('friends').doc(myUid),
        {'name': myName, 'username': myUsername, 'streak': 26},
      );
    }
    await friends.commit();

    // 3) Clear old seed requests to me, then add fresh pending ones.
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
    for (final p in _people.skip(_friendCount).take(_requestCount)) {
      await _db.collection('friend_requests').add({
        'from': p.uid,
        'to': myUid,
        'fromName': p.name,
        'fromUsername': p.username,
        'fromAvatarUrl': p.avatar,
        'message': 'Mình muốn kết bạn với bạn trên WakeLock!',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 4) Feed posts (authored by friends so both feed tabs are full) + their
    // reactions/comments. Deterministic ids keep re-runs idempotent.
    final now = DateTime.now();
    final feed = _db.batch();
    for (var i = 0; i < _postCount; i++) {
      final author = _people[i % _friendCount];
      final reactors = [
        _people[(i + 1) % _friendCount],
        _people[(i + 3) % _friendCount],
        _people[(i + 5) % _friendCount],
      ];
      final ref = _db.collection('posts').doc('seed_post_$i');
      feed.set(ref, {
        'authorUid': author.uid,
        'authorName': author.name,
        'authorUsername': author.username,
        'authorAvatarUrl': author.avatar,
        'photoUrl': 'https://picsum.photos/seed/wl_post_$i/600/600',
        'caption': demoCaptions[i % demoCaptions.length],
        'reactionCount': reactors.length,
        'commentCount': i.isEven ? 1 : 0,
        'createdAt': Timestamp.fromDate(now.subtract(Duration(minutes: i * 43))),
      });
      for (var r = 0; r < reactors.length; r++) {
        feed.set(ref.collection('reactions').doc(reactors[r].uid), {
          'name': reactors[r].name,
          'avatarUrl': reactors[r].avatar,
          'emoji': demoReactEmojis[(i + r) % demoReactEmojis.length],
        });
      }
      if (i.isEven) {
        final commenter = _people[(i + 2) % _friendCount];
        feed.set(ref.collection('comments').doc('seed_c_0'), {
          'uid': commenter.uid,
          'name': commenter.name,
          'avatarUrl': commenter.avatar,
          'text': demoComments[i % demoComments.length],
          'createdAt':
              Timestamp.fromDate(now.subtract(Duration(minutes: i * 43 - 1))),
        });
      }
    }
    await feed.commit();

    // 5) Challenges: one active (hero can check in), one already ended.
    final top = _people.take(8).toList();
    final challengeSeeds = [
      {
        'id': 'seed_challenge_0',
        'title': 'Thử thách dậy sớm 7 ngày',
        'days': 7,
        'start': now.subtract(const Duration(days: 2)),
        'end': now.add(const Duration(days: 5)),
        'active': true,
      },
      {
        'id': 'seed_challenge_1',
        'title': 'Cuối tuần không ngủ nướng',
        'days': 3,
        'start': now.subtract(const Duration(days: 5)),
        'end': now.subtract(const Duration(days: 2)),
        'active': false,
      },
    ];
    final ch = _db.batch();
    for (final c in challengeSeeds) {
      final ref = _db.collection('challenges').doc(c['id'] as String);
      final participants = <String>[myUid, ...top.map((p) => p.uid)];
      ch.set(ref, {
        'title': c['title'],
        'days': c['days'],
        'createdBy': myUid,
        'startAt': Timestamp.fromDate(c['start'] as DateTime),
        'endAt': Timestamp.fromDate(c['end'] as DateTime),
        'participantUids': participants,
      });
      // Hero sits mid-pack; friends checked in yesterday, hero can still act.
      for (var j = 0; j < top.length; j++) {
        final p = top[j];
        ch.set(ref.collection('participants').doc(p.uid), {
          'name': p.name,
          'username': p.username,
          'avatarUrl': p.avatar,
          'score': (c['days'] as int) - (j % (c['days'] as int)),
          'lastCheckIn':
              Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        });
      }
      ch.set(ref.collection('participants').doc(myUid), {
        'name': myName,
        'username': myUsername,
        'avatarUrl': null,
        'score': (c['active'] as bool) ? 4 : 2,
        'lastCheckIn': null,
      });
    }
    await ch.commit();

    // 6) Notifications in the hero's inbox (mirror the real event types).
    final notifs =
        _db.collection('users').doc(myUid).collection('notifications');
    final sampleNotifs = [
      {'type': 'friend_request', 'title': 'Lời mời kết bạn mới', 'body': '${_people[_friendCount].name} muốn kết bạn với bạn', 'actor': _friendCount, 'read': false, 'ago': 5},
      {'type': 'reaction', 'title': 'Cảm xúc mới', 'body': '${_people[0].name} đã thả ❤️ vào bài của bạn', 'actor': 0, 'read': false, 'ago': 40},
      {'type': 'comment', 'title': 'Bình luận mới', 'body': '${_people[1].name} đã bình luận: "Đỉnh quá! 🔥"', 'actor': 1, 'read': false, 'ago': 180},
      {'type': 'friend_accept', 'title': 'Đã trở thành bạn bè', 'body': '${_people[2].name} đã chấp nhận lời mời của bạn', 'actor': 2, 'read': true, 'ago': 600},
      {'type': 'reaction', 'title': 'Cảm xúc mới', 'body': '${_people[3].name} đã thả 🔥 vào bài của bạn', 'actor': 3, 'read': true, 'ago': 900},
      {'type': 'system', 'title': 'Thành tích mới 🏆', 'body': 'Bạn vừa mở khoá "Chuỗi 30 ngày"!', 'actor': 4, 'read': true, 'ago': 1440},
    ];
    final nb = _db.batch();
    for (var i = 0; i < sampleNotifs.length; i++) {
      final n = sampleNotifs[i];
      final actor = _people[n['actor'] as int];
      nb.set(notifs.doc('seed_notif_$i'), {
        'type': n['type'],
        'title': n['title'],
        'body': n['body'],
        'actorName': actor.name,
        'actorAvatarUrl': actor.avatar,
        'read': n['read'],
        'createdAt':
            Timestamp.fromDate(now.subtract(Duration(minutes: n['ago'] as int))),
      });
    }
    await nb.commit();
  }

  /// Remove every seeded artifact and reset the hero's stats to defaults.
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

    // My friend entries pointing at seed users.
    final mine =
        await _db.collection('users').doc(myUid).collection('friends').get();
    final b2 = _db.batch();
    for (final d in mine.docs) {
      if (d.id.startsWith('seed_')) b2.delete(d.reference);
    }
    await b2.commit();

    // Seed user docs + username index + reciprocal friend entry.
    final b3 = _db.batch();
    for (final p in _people) {
      b3.delete(_db.collection('users').doc(p.uid));
      b3.delete(_db.collection('usernames').doc(p.username));
      b3.delete(
          _db.collection('users').doc(p.uid).collection('friends').doc(myUid));
    }
    await b3.commit();

    // Seed posts + their reactions/comments subcollections.
    for (var i = 0; i < _postCount; i++) {
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

    // Seed challenges + participants subcollection.
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

    // Seeded notifications.
    final myNotifs =
        _db.collection('users').doc(myUid).collection('notifications');
    final nbc = _db.batch();
    for (var i = 0; i < _notifCount; i++) {
      nbc.delete(myNotifs.doc('seed_notif_$i'));
    }
    await nbc.commit();

    // Reset the hero's seeded stats back to defaults.
    await _db.collection('users').doc(myUid).set({
      'currentStreak': 0,
      'longestStreak': 0,
      'xp': 0,
      'level': 1,
      'wakeRate': 0,
      'photosShared': 0,
      'coins': 0,
      'ownedItems': <String>[],
      'dailyClaims': <String, String>{},
    }, SetOptions(merge: true));
  }
}
