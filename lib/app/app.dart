import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../features/alarm_management/domain/entities/alarm.dart';
import '../features/alarm_management/presentation/providers/alarm_providers.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/friends/domain/invite_link.dart';
import '../features/friends/presentation/pages/send_invite_page.dart';
import '../features/friends/presentation/providers/friends_providers.dart';
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

  // Friend-invite deep links (wakelock://add?u=<username>).
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // First launch: ask for all hardcore permissions once (notification, exact
    // alarm, overlay, battery, camera). Changeable later in Settings.
    runFirstLaunchPermissionOnboarding();
    // Anti clock-tamper: re-anchor alarms to the real clock on startup.
    _reanchorAlarms();
    // Native pushes the alarm id here when a ring notification is tapped / its
    // full-screen intent fires while the app is already running.
    const MethodChannel('wakelock/ringtones').setMethodCallHandler((call) async {
      if (call.method == 'launchRinging' && call.arguments is String) {
        await _openRinging(call.arguments as String);
      }
    });
    _checkRingingLaunch();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Listen for friend-invite deep links (cold start + while running) and route
  /// to the send-invite screen for the linked username.
  Future<void> _initDeepLinks() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) await _handleInviteLink(initial);
    } catch (e) {
      AppLogger.w('Initial deep link failed: $e');
    }
    _linkSub = _appLinks.uriLinkStream.listen(_handleInviteLink);
  }

  Future<void> _handleInviteLink(Uri uri) async {
    final username = parseInviteUsername(uri.toString());
    if (username == null) return;
    final myUid = ref.read(sessionProvider).asData?.value?.uid;
    if (myUid == null) {
      _snack('Đăng nhập để kết bạn qua link');
      return;
    }
    try {
      final results = await ref
          .read(friendsRepositoryProvider)
          .searchByUsername(username, excludeUid: myUid);
      final match = results.where((p) => p.username == username);
      if (match.isEmpty) {
        _snack('Không tìm thấy @$username');
        return;
      }
      AppRouter.navigatorKey.currentState?.push(
        MaterialPageRoute<void>(
            builder: (_) => SendInvitePage(target: match.first)),
      );
    } catch (e) {
      AppLogger.w('Invite link handling failed: $e');
    }
  }

  void _snack(String message) {
    final ctx = AppRouter.navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The full-screen intent can bring us forward while already running.
      _checkRingingLaunch();
      // An alarm that fired (and a one-shot that self-disabled) while we were
      // backgrounded means the list may be stale — refresh it.
      ref.invalidate(alarmListProvider);
      // Re-anchor alarms in case the system clock was changed to dodge one.
      _reanchorAlarms();
    }
  }

  Future<void> _reanchorAlarms() async {
    try {
      await ref.read(alarmRepositoryProvider).rescheduleAllEnabled();
    } catch (e) {
      AppLogger.w('Reschedule-all failed: $e');
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
