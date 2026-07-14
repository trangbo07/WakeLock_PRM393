import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_firestore_datasource.dart';

class FirestoreNotificationsRepository implements NotificationsRepository {
  FirestoreNotificationsRepository(this._ds);

  final NotificationsFirestoreDataSource _ds;

  @override
  Stream<List<AppNotification>> watch(String uid) =>
      _ds.watch(uid).map((rows) => rows.map(_map).toList());

  @override
  Future<void> markRead(String uid, String id) => _ds.markRead(uid, id);

  @override
  Future<void> markAllRead(String uid) => _ds.markAllRead(uid);

  AppNotification _map(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as String,
        type: m['type'] as String? ?? 'system',
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        actorName: m['actorName'] as String?,
        actorAvatarUrl: m['actorAvatarUrl'] as String?,
        actorAvatarBase64: m['actorAvatarBase64'] as String?,
        read: m['read'] as bool? ?? false,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );
}
