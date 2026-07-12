import 'package:flutter/widgets.dart';

import 'database/app_database.dart';
import 'utils/logger.dart';

/// One-shot application initialization run before `runApp`.
///
/// Ordering matters:
///   1. Flutter bindings
///   2. SQLite database (single source of truth for alarms)
///   3. (later) alarm manager + notifications + foreground service
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

  // TODO: AndroidAlarmManager.initialize() (see core/platform/alarm_scheduler.dart)
  // TODO: init flutter_local_notifications channels (core/constants/notification_channels.dart)
  // TODO: ForegroundServiceController().init() (core/platform/foreground_service.dart)

  AppLogger.i('Bootstrap complete');
}
