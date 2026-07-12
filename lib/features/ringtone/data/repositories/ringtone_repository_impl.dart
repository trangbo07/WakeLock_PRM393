import '../../domain/entities/ringtone.dart';
import '../../domain/repositories/ringtone_repository.dart';

/// Built-in ringtone catalog. The .wav files are generated tones that loop
/// seamlessly via `ReleaseMode.loop`. [highFrequency] flags the piercing,
/// hard-to-sleep-through ones.
class RingtoneRepositoryImpl implements RingtoneRepository {
  static const List<Ringtone> _builtIn = [
    // Modern / melodic — synthesized original tunes (trendy feel).
    Ringtone(
      id: 'marimba',
      name: 'Marimba',
      assetPath: 'assets/ringtones/marimba.wav',
    ),
    Ringtone(
      id: 'melody',
      name: 'Giai điệu vui',
      assetPath: 'assets/ringtones/melody.wav',
    ),
    Ringtone(
      id: 'edm_pluck',
      name: 'EDM Pluck',
      assetPath: 'assets/ringtones/edm_pluck.wav',
    ),
    Ringtone(
      id: 'lofi',
      name: 'Lo-fi chill',
      assetPath: 'assets/ringtones/lofi.wav',
    ),
    Ringtone(
      id: 'arcade',
      name: 'Game retro',
      assetPath: 'assets/ringtones/arcade.wav',
    ),
    Ringtone(
      id: 'bass_drop',
      name: 'Bass Drop',
      assetPath: 'assets/ringtones/bass_drop.wav',
    ),
    // Classic tones.
    Ringtone(
      id: 'default',
      name: 'Mặc định',
      assetPath: 'assets/ringtones/default.wav',
    ),
    Ringtone(
      id: 'beep_slow',
      name: 'Bíp chậm',
      assetPath: 'assets/ringtones/beep_slow.wav',
    ),
    Ringtone(
      id: 'digital',
      name: 'Kỹ thuật số',
      assetPath: 'assets/ringtones/digital.wav',
    ),
    Ringtone(
      id: 'chime',
      name: 'Chuông ngân',
      assetPath: 'assets/ringtones/chime.wav',
    ),
    // Hardcore high-frequency — hard to sleep through.
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
    Ringtone(
      id: 'buzzer',
      name: 'Còi xe',
      assetPath: 'assets/ringtones/buzzer.wav',
      highFrequency: true,
    ),
    Ringtone(
      id: 'pulse',
      name: 'Xung nhịp',
      assetPath: 'assets/ringtones/pulse.wav',
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
