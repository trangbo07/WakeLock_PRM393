/// Android notification channel definitions.
///
/// Two channels with different behavior:
///   - [alarmChannelId]: HIGH importance, full-screen intent, used to launch
///     the ringing UI over the lock screen.
///   - [serviceChannelId]: LOW importance, silent, used by the anti-kill
///     foreground service so the OS keeps the process alive.
class NotificationChannels {
  NotificationChannels._();

  static const String alarmChannelId = 'wakelock_alarm';
  static const String alarmChannelName = 'Báo thức';

  static const String serviceChannelId = 'wakelock_service';
  static const String serviceChannelName = 'Dịch vụ nền WakeLock';
}
