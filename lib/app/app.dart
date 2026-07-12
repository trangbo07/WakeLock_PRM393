import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../features/alarm_management/domain/entities/alarm.dart';
import '../features/alarm_management/presentation/providers/alarm_providers.dart';
import '../features/ringtone/presentation/providers/ringtone_providers.dart';
import '../features/settings/domain/permission_onboarding.dart';
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
  // True while the dismiss screen is on the stack, so a resume (e.g. returning
  // from the camera) doesn't stack a second one.
  bool _ringingVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // First launch: ask for all hardcore permissions once (notification, exact
    // alarm, overlay, battery, camera). Changeable later in Settings.
    runFirstLaunchPermissionOnboarding();
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
    if (state == AppLifecycleState.resumed) {
      // The full-screen intent can bring us forward while already running.
      _checkRingingLaunch();
      // An alarm that fired (and a one-shot that self-disabled) while we were
      // backgrounded means the list may be stale — refresh it.
      ref.invalidate(alarmListProvider);
    }
  }

  Future<void> _checkRingingLaunch() async {
    try {
      // If an alarm is actively ringing, always return to the dismiss screen —
      // works even when the notification was dismissed or the app was reopened
      // from the launcher.
      final alarmId =
          await ref.read(systemRingtoneChannelProvider).currentRingingAlarmId();
      if (alarmId != null && alarmId.isNotEmpty) await _openRinging(alarmId);
    } catch (e) {
      AppLogger.w('Ringing launch check failed: $e');
    }
  }

  Future<void> _openRinging(String alarmId) async {
    if (_ringingVisible) return; // already showing the dismiss screen
    final alarm =
        await ref.read(alarmRepositoryProvider).getAlarmById(alarmId);
    if (alarm == null) {
      AppLogger.w('Ringing launch for unknown alarm $alarmId');
      return;
    }
    _pushRinging(alarm);
  }

  /// The navigator may not exist yet on the very first frame — retry after the
  /// frame instead of dropping the launch. The pushNamed future completes when
  /// the dismiss screen is popped (task done), clearing the guard flag.
  void _pushRinging(Alarm alarm) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pushRinging(alarm));
      return;
    }
    _ringingVisible = true;
    navigator.pushNamed(AppRouter.alarmRinging, arguments: alarm).whenComplete(() {
      _ringingVisible = false;
      // A one-shot that just rang is now disabled — refresh the list toggle.
      ref.invalidate(alarmListProvider);
    });
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
