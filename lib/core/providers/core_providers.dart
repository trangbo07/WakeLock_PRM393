import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../platform/alarm_scheduler.dart';
import '../platform/foreground_service.dart';
import '../platform/overlay_service.dart';
import '../platform/volume_lock_channel.dart';

/// Local SQLite database (pre-opened in `bootstrap()`).
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);

/// Platform-service singletons exposed to the rest of the app via Riverpod.
final alarmSchedulerProvider = Provider<AlarmScheduler>((ref) => AlarmScheduler());
final overlayServiceProvider = Provider<OverlayService>((ref) => OverlayService());
final foregroundServiceProvider =
    Provider<ForegroundServiceController>((ref) => ForegroundServiceController());
final volumeLockProvider = Provider<VolumeLockChannel>((ref) => VolumeLockChannel());
