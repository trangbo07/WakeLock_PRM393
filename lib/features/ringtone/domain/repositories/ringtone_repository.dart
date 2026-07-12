import '../entities/ringtone.dart';

/// Source of selectable ringtones: the device's system alarm sounds plus any
/// audio files the user has added themselves.
abstract interface class RingtoneRepository {
  Future<List<Ringtone>> getRingtones();

  /// Look up a ringtone by its [uri] (the id stored on an alarm).
  Future<Ringtone?> getByUri(String uri);

  /// Copy the audio file at [sourcePath] into app storage and register it as a
  /// custom ringtone. Returns the added ringtone.
  Future<Ringtone> addCustom(String sourcePath);

  /// Remove a user-added ringtone (and its copied file).
  Future<void> removeCustom(String uri);
}
