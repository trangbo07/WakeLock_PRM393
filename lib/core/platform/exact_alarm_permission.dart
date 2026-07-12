import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Ensures the SCHEDULE_EXACT_ALARM permission before scheduling.
///
/// Android 12+ lets the user revoke exact-alarm access; without it
/// `AndroidAlarmManager` falls back to inexact timing — useless for an alarm
/// clock. Returns true when scheduling exactly is allowed.
///
/// Non-Android (widget tests on the dev host) returns true so callers need no
/// platform branching.
Future<bool> ensureExactAlarmPermission() async {
  if (!Platform.isAndroid) return true;

  var status = await Permission.scheduleExactAlarm.status;
  if (status.isGranted) return true;

  // Opens the system "Alarms & reminders" settings screen on Android 12+.
  status = await Permission.scheduleExactAlarm.request();
  return status.isGranted;
}
