import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> signOut() => _auth.signOut();

  /// TODO(Dev2): implement Google Sign-In.
  /// google_sign_in 7.x flow → obtain idToken → sign in to Firebase:
  ///   final cred = GoogleAuthProvider.credential(idToken: idToken);
  ///   final res = await _auth.signInWithCredential(cred);
  ///   return res.user!;
  /// Web client id is in google-services.json (oauth_client type 3).
  Future<User> signInWithGoogle() async {
    throw UnimplementedError('Google Sign-In: wire google_sign_in 7.x (see TODO)');
  }
}
