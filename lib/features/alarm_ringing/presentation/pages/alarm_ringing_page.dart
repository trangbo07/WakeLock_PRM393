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
import '../../data/ringtone_player_service.dart';

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
  final RingtonePlayerService _player = RingtonePlayerService();

  @override
  void initState() {
    super.initState();
    _startRinging();
  }

  /// Every platform call is guarded: a missing plugin (tests) or a failing
  /// native channel must never prevent the screen itself from showing.
  Future<void> _startRinging() async {
    try {
      final ringtone = await ref
          .read(ringtoneRepositoryProvider)
          .getById(widget.alarm.ringtoneId);
      final asset = ringtone?.assetPath ?? 'assets/ringtones/default.wav';
      await _player.play(asset, escalate: widget.alarm.escalateVolume);
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
  }

  /// Tear down sound + volume lock + notification. Fire-and-forget so closing
  /// the screen never waits on native round-trips (each call is guarded so a
  /// missing plugin can't strand the user). Started before pop while `ref` is
  /// still valid; `_player` teardown also happens in [dispose].
  void _teardown() {
    final volumeLock = widget.alarm.volumeLock ? ref.read(volumeLockProvider) : null;
    final notifId = AlarmScheduler.stableId(widget.alarm.id);
    () async {
      try {
        await _player.stop();
      } catch (e) {
        AppLogger.w('Player stop failed: $e');
      }
      try {
        await volumeLock?.unlock();
      } catch (e) {
        AppLogger.w('Volume unlock unavailable: $e');
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
    _player.dispose().catchError((Object e) {
      AppLogger.w('Player dispose failed: $e');
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
