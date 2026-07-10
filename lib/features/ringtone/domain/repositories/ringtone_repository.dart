import '../entities/ringtone.dart';

/// Source of selectable ringtones (built-in bundled assets for now).
abstract interface class RingtoneRepository {
  Future<List<Ringtone>> getRingtones();
  Future<Ringtone?> getById(String id);
}
