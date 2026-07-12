import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';

import 'database/app_database.dart';
import 'utils/logger.dart';

/// One-shot application initialization run before `runApp`.
///
/// Ordering matters:
///   1. Flutter bindings
///   2. SQLite database (single source of truth for alarms)
///   3. Alarm manager (exact scheduling via background isolate)
///   4. (later) notifications + foreground service
///
/// DB init is wrapped defensively so a corrupt file logs loudly instead of
/// blanking the UI; repositories will surface the error to the alarm list.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppDatabase.instance.database;
    AppLogger.i('SQLite database ready');
  } catch (e) {
    AppLogger.e('Database init failed: $e');
  }

  try {
    await AndroidAlarmManager.initialize();
    AppLogger.i('AndroidAlarmManager initialized');
  } catch (e) {
    // Non-Android host (tests) or plugin failure — alarms simply won't fire.
    AppLogger.e('AndroidAlarmManager init failed: $e');
  }

  // TODO: init flutter_local_notifications channels (core/constants/notification_channels.dart)
  // TODO: ForegroundServiceController().init() (core/platform/foreground_service.dart)

  AppLogger.i('Bootstrap complete');
}
