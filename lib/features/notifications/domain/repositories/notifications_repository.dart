import '../entities/app_notification.dart';

/// Notification inbox (`users/{uid}/notifications`).
abstract class NotificationsRepository {
  /// Notifications for [uid], newest first.
  Stream<List<AppNotification>> watch(String uid);

  Future<void> markRead(String uid, String id);
  Future<void> markAllRead(String uid);
}
