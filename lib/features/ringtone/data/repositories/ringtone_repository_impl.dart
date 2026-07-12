import '../../domain/entities/ringtone.dart';
import '../../domain/repositories/ringtone_repository.dart';

/// Built-in ringtone catalog. The .wav files are generated tones (beep /
/// sweep / two-tone) that loop seamlessly via `ReleaseMode.loop`.
class RingtoneRepositoryImpl implements RingtoneRepository {
  static const List<Ringtone> _builtIn = [
    Ringtone(
      id: 'default',
      name: 'Mặc định',
      assetPath: 'assets/ringtones/default.wav',
    ),
    Ringtone(
      id: 'siren',
      name: 'Còi hú',
      assetPath: 'assets/ringtones/siren.wav',
      highFrequency: true,
    ),
    Ringtone(
      id: 'nuclear',
      name: 'Báo động',
      assetPath: 'assets/ringtones/nuclear.wav',
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
