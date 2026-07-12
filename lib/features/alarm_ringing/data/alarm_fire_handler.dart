import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/widgets.dart';

import '../../../core/database/app_database.dart';
import '../../../core/platform/alarm_scheduler.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/logger.dart';
import '../../alarm_management/data/datasources/alarm_local_datasource.dart';
import '../../alarm_management/data/models/alarm_model.dart';

const _ringPackage = 'com.prm393.wakelock_prm393';

/// Entry point executed in a background isolate when a scheduled alarm fires.
///
/// No widget tree / Riverpod here — the alarm config is read straight from
/// SQLite (works offline). Ringing itself is done by a native foreground
/// service ([AlarmSoundService]) so the sound loops reliably and keeps going
/// regardless of the UI; we reach it by broadcasting to [AlarmReceiver]
/// (a broadcast can be sent from this background isolate, a service can't be
/// started directly).
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
      // Standard alarm-clock behavior: a one-shot switches itself off.
      await datasource.setEnabled(alarm.id, enabled: false);
    } else {
      await AlarmScheduler().scheduleOneShot(
        firedIntId,
        DateTimeUtils.nextOccurrence(alarm.hour, alarm.minute, alarm.repeatDays),
        callback: alarmFireHandler,
      );
    }

    await _startRingService(alarm);
  } catch (e) {
    AppLogger.e('alarmFireHandler failed: $e');
  }
}

/// Broadcast to the native receiver, which starts the looping-sound service.
Future<void> _startRingService(AlarmModel alarm) async {
  final intent = AndroidIntent(
    action: '$_ringPackage.action.RING',
    package: _ringPackage,
    componentName: '$_ringPackage.AlarmReceiver',
    arguments: <String, dynamic>{
      'soundUri': alarm.ringtoneId,
      'escalate': alarm.escalateVolume,
      'vibrate': alarm.vibrate,
      'flashlight': alarm.flashlight,
      'label': alarm.label.isEmpty ? 'Báo thức' : alarm.label,
      'alarmId': alarm.id,
    },
  );
  await intent.sendBroadcast();
}

/// The scheduler only knows the stable int id — map it back to the alarm row.
AlarmModel? findByFiredId(List<AlarmModel> alarms, int firedIntId) {
  for (final a in alarms) {
    if (AlarmScheduler.stableId(a.id) == firedIntId) return a;
  }
  return null;
}
