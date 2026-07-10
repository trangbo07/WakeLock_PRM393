import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<void> signInAnonymously() async {
    await _client.auth.signInAnonymously();
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  bool get isSignedIn => _client.auth.currentSession != null;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;
}
