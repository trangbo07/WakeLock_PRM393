import 'package:equatable/equatable.dart';

/// App-level user identity, mapped from a Firebase [User]. Keeps the rest of
/// the app decoupled from the Firebase SDK type.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl];
}
