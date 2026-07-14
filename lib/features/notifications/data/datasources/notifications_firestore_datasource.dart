import 'package:cloud_firestore/cloud_firestore.dart';

CollectionReference<Map<String, dynamic>> _inbox(
        FirebaseFirestore db, String uid) =>
    db.collection('users').doc(uid).collection('notifications');

/// Adds a notification to [toUid]'s inbox. Shared helper called by the friends
/// and feed data sources so notifications come from real events. Fire-and-forget
/// (best-effort — a failed notification must not break the triggering action).
Future<void> pushNotification(
  FirebaseFirestore db,
  String toUid, {
  required String type,
  required String title,
  required String body,
  String? actorName,
  String? actorAvatarUrl,
  String? actorAvatarBase64,
}) async {
  try {
    await _inbox(db, toUid).add({
      'type': type,
      'title': title,
      'body': body,
      'actorName': actorName,
      'actorAvatarUrl': actorAvatarUrl,
      'actorAvatarBase64': actorAvatarBase64,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (_) {/* best-effort */}
}

/// Read side of the notification inbox.
class NotificationsFirestoreDataSource {
  NotificationsFirestoreDataSource([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<Map<String, dynamic>>> watch(String uid) => _inbox(_db, uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  Future<void> markRead(String uid, String id) =>
      _inbox(_db, uid).doc(id).update({'read': true});

  Future<void> markAllRead(String uid) async {
    final unread =
        await _inbox(_db, uid).where('read', isEqualTo: false).get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }
}
