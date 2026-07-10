/// Authentication abstraction backed by Supabase Auth.
///
/// Anonymous sign-in is enough to associate alarms with a device/user via RLS;
/// email/OAuth can be layered on later without changing call sites.
abstract interface class AuthRepository {
  Future<void> signInAnonymously();
  Future<void> signOut();
  bool get isSignedIn;
  String? get currentUserId;
}
