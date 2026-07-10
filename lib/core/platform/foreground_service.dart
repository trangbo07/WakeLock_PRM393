import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Controls the anti-kill foreground service ("chống tắt ngầm").
///
/// A persistent low-priority notification keeps the process alive overnight so
/// Android's memory manager won't reclaim it before an alarm fires.
///
/// The exact `FlutterForegroundTask.init(...)` config (channel, options) is
/// version-sensitive — wire it up in `bootstrap()` per the installed
/// flutter_foreground_task version docs before calling [start].
class ForegroundServiceController {
  /// Start the persistent notification / service.
  Future<void> start() {
    return FlutterForegroundTask.startService(
      notificationTitle: 'WakeLock đang bảo vệ báo thức',
      notificationText: 'Nhấn để mở ứng dụng',
    );
  }

  Future<void> stop() => FlutterForegroundTask.stopService();

  Future<bool> get isRunning => FlutterForegroundTask.isRunningService;
}
