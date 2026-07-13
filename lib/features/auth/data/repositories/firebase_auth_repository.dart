import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

/// Firebase-backed [AuthRepository]. Maps the SDK [User] to [AppUser] so the
/// rest of the app never imports firebase_auth directly.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._ds);

  final FirebaseAuthDataSource _ds;

  AppUser _map(User u) => AppUser(
        uid: u.uid,
        email: u.email,
        displayName: u.displayName,
        photoUrl: u.photoURL,
      );

  @override
  Stream<AppUser?> authState() =>
      _ds.authState().map((u) => u == null ? null : _map(u));

  @override
  AppUser? get currentUser {
    final u = _ds.currentUser;
    return u == null ? null : _map(u);
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async =>
      _map(await _ds.signInWithEmail(email, password));

  @override
  Future<AppUser> registerWithEmail(String email, String password) async =>
      _map(await _ds.registerWithEmail(email, password));

  @override
  Future<void> sendPasswordReset(String email) => _ds.sendPasswordReset(email);

  @override
  Future<AppUser> signInWithGoogle() async => _map(await _ds.signInWithGoogle());

  @override
  Future<void> signOut() => _ds.signOut();
}
