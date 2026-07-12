import 'package:flutter/widgets.dart';

import '../../../core/database/app_database.dart';
import '../../../core/platform/alarm_notification_service.dart';
import '../../../core/platform/alarm_scheduler.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/logger.dart';
import '../../alarm_management/data/datasources/alarm_local_datasource.dart';
import '../../alarm_management/data/models/alarm_model.dart';

/// Entry point executed in a background isolate when a scheduled alarm fires.
///
/// No widget tree / Riverpod here — services are constructed by hand and the
/// alarm config is read straight from SQLite (works offline). The heavy UI
/// (ringing page + sound) runs in the main isolate, launched via the
/// full-screen notification, so that completing a task can stop the sound.
@pragma('vm:entry-point')
Future<void> alarmFireHandler(int firedIntId) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final datasource = AlarmLocalDataSource(AppDatabase.instance);
    final alarm = findByFiredId(await datasource.fetchAll(), firedIntId);
    if (alarm == null || !alarm.isEnabled) {
      AppLogger.w('alarmFireHandler: no enabled alarm for id $firedIntId');
      return;
    }

    if (alarm.isOneShot) {
      // Standard alarm-clock behavior: a one-shot switches itself off after
      // firing so it doesn't ring again tomorrow.
      await datasource.setEnabled(alarm.id, enabled: false);
    } else {
      await AlarmScheduler().scheduleOneShot(
        firedIntId,
        DateTimeUtils.nextOccurrence(alarm.hour, alarm.minute, alarm.repeatDays),
        callback: alarmFireHandler,
      );
    }

    await AlarmNotificationService.showRinging(
      notificationId: firedIntId,
      alarmId: alarm.id,
      title: alarm.label.isEmpty ? 'Báo thức' : alarm.label,
    );
  } catch (e) {
    AppLogger.e('alarmFireHandler failed: $e');
  }
}

/// The scheduler only knows the stable int id — map it back to the alarm row.
/// Linear scan is fine: users have a handful of alarms.
AlarmModel? findByFiredId(List<AlarmModel> alarms, int firedIntId) {
  for (final a in alarms) {
    if (AlarmScheduler.stableId(a.id) == firedIntId) return a;
  }
  return null;
}
