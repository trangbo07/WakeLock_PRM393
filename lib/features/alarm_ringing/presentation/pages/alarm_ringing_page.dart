import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/alarm_notification_service.dart';
import '../../../../core/platform/alarm_scheduler.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/logger.dart';
import '../../../alarm_management/domain/entities/alarm.dart';
import '../../../ringtone/presentation/providers/ringtone_providers.dart';
import '../../../task/domain/entities/task_result.dart';
import '../../../task/presentation/task_runner_page.dart';

/// Full-screen, hard-to-escape ringing screen.
///
/// Owns the whole "alarm is ringing" lifecycle in the UI isolate:
/// start looping ringtone (+ escalation), pin volume via the native channel,
/// and tear everything down only when the dismiss task succeeds. [PopScope]
/// blocks the back button; the screen appears over the lock screen thanks to
/// the full-screen-intent notification + showWhenLocked on MainActivity.
class AlarmRingingPage extends ConsumerStatefulWidget {
  const AlarmRingingPage({super.key, required this.alarm});

  final Alarm alarm;

  @override
  ConsumerState<AlarmRingingPage> createState() => _AlarmRingingPageState();
}

class _AlarmRingingPageState extends ConsumerState<AlarmRingingPage> {
  // Captured in initState so dispose() can stop the sound without touching
  // `ref` during widget-tree finalization (Riverpod forbids that).
  late final _ringtoneChannel = ref.read(systemRingtoneChannelProvider);

  @override
  void initState() {
    super.initState();
    _startRinging();
  }

  /// Every platform call is guarded: a missing plugin (tests) or a failing
  /// native channel must never prevent the screen itself from showing.
  Future<void> _startRinging() async {
    try {
      // The device system sound (or the user's custom file) is played natively
      // by RingtoneManager, looping on the alarm stream.
      await _ringtoneChannel.startAlarm(
        widget.alarm.ringtoneId,
        escalate: widget.alarm.escalateVolume,
      );
    } catch (e) {
      AppLogger.e('Ringtone playback failed: $e');
    }
    if (widget.alarm.volumeLock) {
      try {
        await ref.read(volumeLockProvider).lockToMax();
      } catch (e) {
        AppLogger.w('Volume lock unavailable: $e');
      }
    }
    // Anti-kill: keep this process alive so the alarm can't be silenced by the
    // OS reclaiming memory mid-ring.
    try {
      await ref.read(foregroundServiceProvider).start();
    } catch (e) {
      AppLogger.w('Foreground service start failed: $e');
    }
  }

  /// Tear down sound + volume lock + notification. Fire-and-forget so closing
  /// the screen never waits on native round-trips (each call is guarded so a
  /// missing plugin can't strand the user). Started before pop while `ref` is
  /// still valid; `_player` teardown also happens in [dispose].
  void _teardown() {
    final volumeLock = widget.alarm.volumeLock ? ref.read(volumeLockProvider) : null;
    final foregroundService = ref.read(foregroundServiceProvider);
    final notifId = AlarmScheduler.stableId(widget.alarm.id);
    () async {
      try {
        await _ringtoneChannel.stopAlarm();
      } catch (e) {
        AppLogger.w('Alarm sound stop failed: $e');
      }
      try {
        await volumeLock?.unlock();
      } catch (e) {
        AppLogger.w('Volume unlock unavailable: $e');
      }
      try {
        await foregroundService.stop();
      } catch (e) {
        AppLogger.w('Foreground service stop failed: $e');
      }
      try {
        await AlarmNotificationService.cancel(notifId);
      } catch (e) {
        AppLogger.w('Notification cancel failed: $e');
      }
    }();
  }

  Future<void> _attemptDismiss() async {
    final result = await Navigator.push<TaskResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskRunnerPage(config: widget.alarm.dismissTask),
      ),
    );
    if (!mounted) return;
    if (result?.completed ?? false) {
      _teardown();
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    // Safety net: stop the sound if the screen is torn down without dismiss.
    _ringtoneChannel.stopAlarm().catchError((Object e) {
      AppLogger.w('Alarm sound stop failed: $e');
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alarm = widget.alarm;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateTimeUtils.formatHm(alarm.hour, alarm.minute),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary, // amber
                    fontSize: 72,
                    fontWeight: FontWeight.w700,
                    // Tabular figures keep the digits from jittering.
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alarm.label.isEmpty ? 'Báo thức' : alarm.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 22),
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: _attemptDismiss,
                  icon: const Icon(Icons.alarm_off),
                  label: const Text('Tắt báo thức'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
