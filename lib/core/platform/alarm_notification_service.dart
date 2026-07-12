import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/notification_channels.dart';

/// Full-screen alarm notifications (flutter_local_notifications).
///
/// The full-screen intent is what brings the ringing UI up over the lock
/// screen: MainActivity has `showWhenLocked` + `turnScreenOn`, so posting this
/// notification launches the activity even while locked. Sound is NOT played
/// by the notification — `RingtonePlayerService` owns audio in the UI isolate
/// so completing a task can actually stop it.
///
/// All members are static because the background alarm isolate needs
/// [showRinging] without any app wiring; [_ensureInitialized] makes each
/// isolate initialize its own plugin instance exactly once.
class AlarmNotificationService {
  AlarmNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const InitializationSettings _settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );

  /// Main-isolate init. [onAlarmTapped] receives the alarm UUID when the user
  /// taps the notification while the app is already running. Also asks for
  /// POST_NOTIFICATIONS (Android 13+) — without it nothing is shown at all.
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

  /// Alarm UUID whose notification launched the app (full-screen intent or
  /// tap), or null on a normal launch. Check once at startup.
  static Future<String?> launchAlarmId() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details!.notificationResponse?.payload;
    }
    return null;
  }

  /// Post the ringing notification. [notificationId] is the alarm's stable
  /// int id so the ringing page can cancel exactly this one.
  static Future<void> showRinging({
    required int notificationId,
    required String alarmId,
    required String title,
  }) async {
    await _ensureInitialized();
    const android = AndroidNotificationDetails(
      NotificationChannels.alarmChannelId,
      NotificationChannels.alarmChannelName,
      channelDescription: 'Báo thức đang reo',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      fullScreenIntent: true,
      playSound: false,
      ongoing: true,
      autoCancel: false,
    );
    await _plugin.show(
      id: notificationId,
      title: title,
      body: 'Hoàn thành nhiệm vụ để tắt báo thức',
      notificationDetails: const NotificationDetails(android: android),
      payload: alarmId,
    );
  }

  static Future<void> cancel(int notificationId) async {
    await _ensureInitialized();
    await _plugin.cancel(id: notificationId);
  }
}
