import 'package:equatable/equatable.dart';

/// A selectable alarm sound: either a device system ringtone or a file the
/// user added themselves.
///
/// [uri] is the Android content:// URI, an absolute file path (user-picked
/// file), or the sentinel `'default'` for the system default alarm. It doubles
/// as the stable id stored on an alarm.
class Ringtone extends Equatable {
  const Ringtone({
    required this.uri,
    required this.name,
    this.isCustom = false,
  });

  final String uri;
  final String name;

  /// True for a file the user added (can be removed by the user).
  final bool isCustom;

  @override
  List<Object?> get props => [uri, name, isCustom];
}
