import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Plays the alarm sound in a loop, optionally escalating volume from low to
/// max over a fixed ramp ("tăng dần âm lượng").
class RingtonePlayerService {
  final AudioPlayer _player = AudioPlayer();
  Timer? _escalateTimer;

  /// Start playback. [assetPath] is a pubspec asset path like
  /// `assets/ringtones/siren.mp3`.
  Future<void> play(String assetPath, {bool escalate = true}) async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(escalate ? 0.2 : 1.0);

    // AssetSource paths are relative to the `assets/` root.
    final source = assetPath.replaceFirst('assets/', '');
    await _player.play(AssetSource(source));

    if (escalate) _startEscalation();
  }

  void _startEscalation() {
    _escalateTimer?.cancel();
    var volume = 0.2;
    _escalateTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      volume = (volume + 0.2).clamp(0.0, 1.0);
      await _player.setVolume(volume);
      if (volume >= 1.0) timer.cancel();
    });
  }

  Future<void> stop() async {
    _escalateTimer?.cancel();
    await _player.stop();
  }

  Future<void> dispose() async {
    _escalateTimer?.cancel();
    await _player.dispose();
  }
}
