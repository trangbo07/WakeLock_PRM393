import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../constants/notification_channels.dart';

/// Controls the anti-kill foreground service ("chống tắt ngầm").
///
/// A persistent notification keeps the process alive while an alarm is ringing
/// so Android's memory manager won't reclaim it mid-alarm. [init] must run once
/// in `bootstrap()` before [start].
class ForegroundServiceController {
  /// One-time configuration. Safe to call from any isolate.
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: NotificationChannels.serviceChannelId,
        channelName: NotificationChannels.serviceChannelName,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  /// Start the persistent notification / service.
  Future<void> start() {
    return FlutterForegroundTask.startService(
      serviceTypes: [
        ForegroundServiceTypes.mediaPlayback,
        ForegroundServiceTypes.specialUse,
      ],
      notificationTitle: 'WakeLock đang bảo vệ báo thức',
      notificationText: 'Nhấn để mở ứng dụng',
    );
  }

  Future<void> stop() => FlutterForegroundTask.stopService();

  Future<bool> get isRunning => FlutterForegroundTask.isRunningService;
}
