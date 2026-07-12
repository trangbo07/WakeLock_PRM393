import 'package:flutter/services.dart';

import '../../features/ringtone/domain/entities/ringtone.dart';

/// Bridge to the device's real alarm sounds (native RingtoneManager) and the
/// native ring service. No audio is bundled with the app — the user picks from
/// Android's own alarm ringtones or a file they add themselves.
class SystemRingtoneChannel {
  static const MethodChannel _channel = MethodChannel('wakelock/ringtones');

  /// The device's alarm sounds (default first).
  Future<List<Ringtone>> list() async {
    final raw = await _channel.invokeListMethod<Map<dynamic, dynamic>>('list');
    if (raw == null) return const [];
    return raw
        .map((m) => Ringtone(
              uri: (m['uri'] as String?) ?? 'default',
              name: (m['title'] as String?) ?? 'Nhạc chuông',
            ))
        .toList(growable: false);
  }

  /// The system default alarm sound as a concrete content:// URI (or '' if
  /// unavailable / non-Android). Resolves the 'default' sentinel to a real URI.
  Future<String> defaultAlarmUri() async {
    try {
      return (await _channel.invokeMethod<String>('defaultAlarmUri')) ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> preview(String uri) =>
      _channel.invokeMethod('preview', {'uri': uri});

  Future<void> stopPreview() => _channel.invokeMethod('stopPreview');

  /// UUID of the alarm currently ringing (the ring service is active), or null.
  /// The app checks this on start/resume so opening the app while an alarm
  /// rings always returns to the dismiss screen — even if the user swiped the
  /// notification away.
  Future<String?> currentRingingAlarmId() async {
    try {
      return _channel.invokeMethod<String>('currentRingingAlarmId');
    } catch (_) {
      return null;
    }
  }

  /// Stop the looping alarm sound service (called when the task is completed).
  Future<void> stopRinging() => _channel.invokeMethod('stopRinging');
}
