import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper over the Firebase Auth SDK. Returns raw [User]; the repository
/// maps to AppUser. Email/password + reset + sign-out are wired; Google
/// Sign-In is a TODO for Dev 2 (needs google_sign_in 7.x).
class FirebaseAuthDataSource {
  FirebaseAuthDataSource([FirebaseAuth? auth])
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> authState() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return cred.user!;
  }

  Future<User> registerWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return cred.user!;
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() async {
    // Also clear the Google session so the next sign-in shows the account picker.
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Google Sign-In (google_sign_in 6.x): pick account → exchange tokens for a
  /// Firebase credential. Throws code 'canceled' if the user dismisses the sheet.
  Future<User> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'canceled',
        message: 'Đã huỷ đăng nhập Google',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user!;
  }
}
