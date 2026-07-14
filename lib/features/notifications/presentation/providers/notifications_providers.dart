import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/notifications_firestore_datasource.dart';
import '../../data/repositories/firestore_notifications_repository.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

final notificationsDataSourceProvider =
    Provider<NotificationsFirestoreDataSource>(
  (ref) => NotificationsFirestoreDataSource(),
);

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) =>
      FirestoreNotificationsRepository(ref.watch(notificationsDataSourceProvider)),
);

/// The signed-in user's notifications, newest first (empty for guests).
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(sessionProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(notificationsRepositoryProvider).watch(uid);
});

/// Number of unread notifications (for the bell badge).
final unreadCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider).asData?.value ?? const [];
  return list.where((n) => !n.read).length;
});
