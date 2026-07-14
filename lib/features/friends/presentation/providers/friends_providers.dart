import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/friends_firestore_datasource.dart';
import '../../data/repositories/firestore_friends_repository.dart';
import '../../domain/entities/friend.dart';
import '../../domain/repositories/friends_repository.dart';

final friendsDataSourceProvider = Provider<FriendsFirestoreDataSource>(
  (ref) => FriendsFirestoreDataSource(),
);

final friendsRepositoryProvider = Provider<FriendsRepository>(
  (ref) => FirestoreFriendsRepository(ref.watch(friendsDataSourceProvider)),
);

/// The signed-in user's accepted friends (empty for guests).
final friendsListProvider = StreamProvider<List<Friend>>((ref) {
  final uid = ref.watch(sessionProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(friendsRepositoryProvider).watchFriends(uid);
});

/// Pending incoming friend requests for the signed-in user.
final friendRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  final uid = ref.watch(sessionProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(friendsRepositoryProvider).watchIncomingRequests(uid);
});
