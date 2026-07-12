import '../../domain/entities/ringtone.dart';
import '../../domain/repositories/ringtone_repository.dart';

/// Built-in ringtone catalog.
///
/// TODO: drop real audio files under `assets/ringtones/` and register them in
/// `pubspec.yaml`.
class RingtoneRepositoryImpl implements RingtoneRepository {
  static const List<Ringtone> _builtIn = [
    Ringtone(
      id: 'default',
      name: 'Mặc định',
      assetPath: 'assets/ringtones/default.mp3',
    ),
    Ringtone(
      id: 'siren',
      name: 'Còi hú',
      assetPath: 'assets/ringtones/siren.mp3',
      highFrequency: true,
    ),
    Ringtone(
      id: 'nuclear',
      name: 'Báo động',
      assetPath: 'assets/ringtones/nuclear.mp3',
      highFrequency: true,
    ),
  ];

  @override
  Future<List<Ringtone>> getRingtones() async => _builtIn;

  @override
  Future<Ringtone?> getById(String id) async {
    for (final r in _builtIn) {
      if (r.id == id) return r;
    }
    return null;
  }
}
