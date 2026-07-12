import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/notification_channels.dart';

/// Full-screen alarm notifications (flutter_local_notifications).
///
/// The notification does the ringing: it plays the alarm sound looping
/// (FLAG_INSISTENT) on the alarm stream the moment it is posted from the
/// background isolate — so the alarm rings automatically at the scheduled time
/// WITHOUT the user having to tap it, whether the screen is locked or not.
/// The full-screen intent additionally brings up the dismiss UI. Cancelling the
/// notification (when the task is completed) stops the looping sound.
///
/// System sounds are content:// URIs and play here. A user's custom file (an
/// app-private path) can't be read by the system notifier, so for those the
/// notification stays silent and the ringing screen plays them instead.
class AlarmNotificationService {
  AlarmNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const InitializationSettings _settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  /// FLAG_INSISTENT — repeat the notification sound until it is cancelled.
  static final Int32List _insistent = Int32List.fromList([4]);

  static Future<void> init({
    required void Function(String alarmId) onAlarmTapped,
  }) async {
    await _plugin.initialize(
      settings: _settings,
      onDidReceiveNotificationResponse: (response) {
        final alarmId = response.payload;
        if (alarmId != null && alarmId.isNotEmpty) onAlarmTapped(alarmId);
      },
    );
    _initialized = true;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _plugin.initialize(settings: _settings);
    _initialized = true;
  }

  static Future<String?> launchAlarmId() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }

  /// Post the ringing notification. When [soundUri] is a content:// URI, the
  /// notification plays it looping; otherwise it stays silent (custom file).
  static Future<void> showRinging({
    required int notificationId,
    required String alarmId,
    required String title,
    required String soundUri,
  }) async {
    await _ensureInitialized();

    final playsSound = soundUri.startsWith('content://');
    // A channel's sound is fixed at creation, so give each distinct sound its
    // own channel; otherwise every alarm would reuse the first sound ever set.
    final channelId = playsSound
        ? 'wakelock_alarm_${soundUri.hashCode}'
        : NotificationChannels.alarmChannelId;

    final android = AndroidNotificationDetails(
      channelId,
      NotificationChannels.alarmChannelName,
      channelDescription: 'Báo thức đang reo',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      fullScreenIntent: true,
      playSound: playsSound,
      sound: playsSound ? UriAndroidNotificationSound(soundUri) : null,
      additionalFlags: _insistent,
      ongoing: true,
      autoCancel: false,
    );
    await _plugin.show(
      id: notificationId,
      title: title,
      body: 'Hoàn thành nhiệm vụ để tắt báo thức',
      notificationDetails: NotificationDetails(android: android),
      payload: alarmId,
    );
  }

  static Future<void> cancel(int notificationId) async {
    await _ensureInitialized();
    await _plugin.cancel(id: notificationId);
  }
}
