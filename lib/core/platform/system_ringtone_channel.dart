import 'package:flutter/services.dart';

import '../../features/ringtone/domain/entities/ringtone.dart';

/// Bridge to the device's real alarm sounds (native RingtoneManager, see
/// android/.../SystemRingtones.kt). No audio is bundled with the app — the
/// user picks from Android's own built-in alarm ringtones.
class SystemRingtoneChannel {
  static const MethodChannel _channel = MethodChannel('wakelock/ringtones');

  /// The device's alarm sounds ("default" sentinel first).
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

  Future<void> preview(String uri) =>
      _channel.invokeMethod('preview', {'uri': uri});

  Future<void> stopPreview() => _channel.invokeMethod('stopPreview');

  /// Loop [uri] on the alarm stream; [escalate] ramps volume up over time.
  Future<void> startAlarm(String uri, {required bool escalate}) =>
      _channel.invokeMethod('startAlarm', {'uri': uri, 'escalate': escalate});

  Future<void> stopAlarm() => _channel.invokeMethod('stopAlarm');
}
