import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/profile_firestore_datasource.dart';
import '../../data/repositories/firestore_profile_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

/// DI for the profile feature.
final profileFirestoreDataSourceProvider = Provider<ProfileFirestoreDataSource>(
  (ref) => ProfileFirestoreDataSource(),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) =>
      FirestoreProfileRepository(ref.watch(profileFirestoreDataSourceProvider)),
);

/// The signed-in user's profile (null when guest). Watches [sessionProvider]
/// for the uid, then streams the Firestore doc. No Firestore call while guest.
final myProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(sessionProvider).asData?.value;
  if (user == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(user.uid);
});

/// Any user's profile by uid — used for friend profiles.
final userProfileProvider = FutureProvider.family<UserProfile?, String>(
  (ref, uid) => ref.watch(profileRepositoryProvider).getProfile(uid),
);
