import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../platform/alarm_scheduler.dart';
import '../platform/foreground_service.dart';
import '../platform/overlay_service.dart';
import '../platform/volume_lock_channel.dart';

/// Global Supabase client (initialized in `bootstrap()`).
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Platform-service singletons exposed to the rest of the app via Riverpod.
final alarmSchedulerProvider = Provider<AlarmScheduler>((ref) => AlarmScheduler());
final overlayServiceProvider = Provider<OverlayService>((ref) => OverlayService());
final foregroundServiceProvider =
    Provider<ForegroundServiceController>((ref) => ForegroundServiceController());
final volumeLockProvider = Provider<VolumeLockChannel>((ref) => VolumeLockChannel());
