import '../entities/app_user.dart';

/// Authentication contract. Implemented with Firebase Auth
/// (see FirebaseAuthRepository). `null` from [authState]/[currentUser] means
/// guest (not signed in) — the offline alarm core works fine in that state.
abstract class AuthRepository {
  /// Emits the current user on login/logout; `null` when signed out.
  Stream<AppUser?> authState();

  AppUser? get currentUser;

  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> registerWithEmail(String email, String password);
  Future<void> sendPasswordReset(String email);

  /// Google Sign-In (google_sign_in 7.x). See datasource TODO.
  Future<AppUser> signInWithGoogle();

  Future<void> signOut();
}
