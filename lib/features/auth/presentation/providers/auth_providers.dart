import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// DI for the auth feature.
final authDataSourceProvider = Provider<FirebaseAuthDataSource>(
  (ref) => FirebaseAuthDataSource(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(ref.watch(authDataSourceProvider)),
);

/// Current signed-in user, or `null` for guest. THE gate for social features:
/// watch this and show a "sign in" prompt when null. Offline features ignore it.
final sessionProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authState(),
);
