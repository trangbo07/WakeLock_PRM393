import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/platform/alarm_notification_service.dart';
import '../core/utils/logger.dart';
import '../features/alarm_management/domain/entities/alarm.dart';
import '../features/alarm_management/presentation/providers/alarm_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget. Wires up theme + routing, and routes into the ringing screen
/// when an alarm notification launched the app (full-screen intent) or was
/// tapped while the app is running.
class WakeLockApp extends ConsumerStatefulWidget {
  const WakeLockApp({super.key});

  @override
  ConsumerState<WakeLockApp> createState() => _WakeLockAppState();
}

class _WakeLockAppState extends ConsumerState<WakeLockApp> {
  @override
  void initState() {
    super.initState();
    _wireAlarmLaunch();
  }

  Future<void> _wireAlarmLaunch() async {
    try {
      await AlarmNotificationService.init(onAlarmTapped: _openRinging);
      final launchId = await AlarmNotificationService.launchAlarmId();
      if (launchId != null) await _openRinging(launchId);
    } catch (e) {
      // Missing plugin on the test host must not break app startup.
      AppLogger.w('Alarm notification wiring unavailable: $e');
    }
  }

  Future<void> _openRinging(String alarmId) async {
    final alarm =
        await ref.read(alarmRepositoryProvider).getAlarmById(alarmId);
    if (alarm == null) {
      AppLogger.w('Ringing launch for unknown alarm $alarmId');
      return;
    }
    _pushRinging(alarm);
  }

  /// The navigator may not exist yet on the very first frame — retry after the
  /// frame instead of dropping the launch.
  void _pushRinging(Alarm alarm) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pushRinging(alarm));
      return;
    }
    navigator.pushNamed(AppRouter.alarmRinging, arguments: alarm);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      navigatorKey: AppRouter.navigatorKey,
      initialRoute: AppRouter.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
