import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../features/alarm_management/domain/entities/alarm.dart';
import '../features/alarm_management/presentation/providers/alarm_providers.dart';
import '../features/ringtone/presentation/providers/ringtone_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget. Wires up theme + routing, and routes into the ringing screen
/// when the native ring service's full-screen notification launched the app
/// (its intent carries the alarm id, read via [SystemRingtoneChannel]).
class WakeLockApp extends ConsumerStatefulWidget {
  const WakeLockApp({super.key});

  @override
  ConsumerState<WakeLockApp> createState() => _WakeLockAppState();
}

class _WakeLockAppState extends ConsumerState<WakeLockApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The ring service posts a foreground notification (Android 13+ needs this).
    Permission.notification.request().ignore();
    // Native pushes the alarm id here when a ring notification is tapped / its
    // full-screen intent fires while the app is already running.
    const MethodChannel('wakelock/ringtones').setMethodCallHandler((call) async {
      if (call.method == 'launchRinging' && call.arguments is String) {
        await _openRinging(call.arguments as String);
      }
    });
    _checkRingingLaunch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The full-screen intent can bring us forward while already running.
    if (state == AppLifecycleState.resumed) _checkRingingLaunch();
  }

  Future<void> _checkRingingLaunch() async {
    try {
      final alarmId =
          await ref.read(systemRingtoneChannelProvider).consumeLaunchAlarmId();
      if (alarmId != null && alarmId.isNotEmpty) await _openRinging(alarmId);
    } catch (e) {
      AppLogger.w('Ringing launch check failed: $e');
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
    // Avoid stacking duplicate ringing screens if resumed repeatedly.
    navigator.popUntil((r) => r.settings.name != AppRouter.alarmRinging);
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
