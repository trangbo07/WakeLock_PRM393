import 'package:flutter/services.dart';

/// Bridge to native Android code that pins the alarm stream to max volume and
/// swallows the hardware volume-down key while an alarm is ringing
/// ("chặn quyền giảm âm lượng của hệ thống").
///
/// The native side (MainActivity / a plugin) must register a MethodChannel
/// named [_channelName] and handle `lockToMax` / `unlock`. This Dart wrapper is
/// intentionally dependency-free so it compiles before the native side exists.
class VolumeLockChannel {
  static const String _channelName = 'wakelock/volume';
  static const MethodChannel _channel = MethodChannel(_channelName);

  /// Raise the alarm stream to max and start intercepting volume-down.
  Future<void> lockToMax() => _channel.invokeMethod('lockToMax');

  /// Release the lock and restore normal volume-key behavior.
  Future<void> unlock() => _channel.invokeMethod('unlock');
}
