import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/alarm_scheduler.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/logger.dart';
import '../../../alarm_management/domain/entities/alarm.dart';
import '../../../emergency/presentation/pages/emergency_sos_page.dart';
import '../../../morning_photo/presentation/pages/morning_photo_capture_page.dart';
import '../../../ringtone/presentation/providers/ringtone_providers.dart';
import '../../../routine/presentation/pages/routine_execute_page.dart';
import '../../../streak/domain/entities/wake_event.dart';
import '../../../streak/presentation/providers/wake_event_providers.dart';
import '../../../task/domain/entities/task_result.dart';
import '../../../task/presentation/task_runner_page.dart';
import '../../data/alarm_fire_handler.dart';

/// Full-screen, hard-to-escape dismiss screen.
///
/// The looping alarm sound is played by the native [AlarmSoundService], so it
/// keeps ringing even if this screen is closed — the screen is the dismiss UI.
/// It pins/locks the volume and keeps the screen on (via the volume channel's
/// window flags), blocks Back ([PopScope]), and stops the ring service only
/// when the dismiss task succeeds.
///
/// Also the wake-flow host: records the `wake_events` row for this firing,
/// offers "Báo lại" (snooze) and "Cần trợ giúp" (SOS), and after a successful
/// dismiss chains into the linked Routine (if any) then the Morning Photo
/// capture flow before finally leaving the screen.
class AlarmRingingPage extends ConsumerStatefulWidget {
  const AlarmRingingPage({super.key, required this.alarm});

  final Alarm alarm;

  @override
  ConsumerState<AlarmRingingPage> createState() => _AlarmRingingPageState();
}

class _AlarmRingingPageState extends ConsumerState<AlarmRingingPage> {
  // Captured in initState so teardown can use it without touching `ref` during
  // widget-tree finalization (Riverpod forbids that).
  late final _ringtoneChannel = ref.read(systemRingtoneChannelProvider);

  // Screen strobe (flashbang) — syncs roughly with the native torch strobe.
  Timer? _strobeTimer;
  bool _strobeBright = false;

  // wake_events row for this firing (reused across snooze re-fires — see
  // _recordFired). Null while the initial DB round-trip is still in flight or
  // if it failed (never blocks ringing/dismissal on a DB error).
  String? _wakeEventId;
  int _snoozeCount = 0;
  bool _snoozing = false;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _lockDown();
    _recordFired();
    if (widget.alarm.flashlight) {
      _strobeTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
        if (mounted) setState(() => _strobeBright = !_strobeBright);
      });
    }
  }

  @override
  void dispose() {
    _strobeTimer?.cancel();
    super.dispose();
  }

  /// Pin the volume + keep the screen on / over the keyguard. The sound itself
  /// is already looping in the native service.
  Future<void> _lockDown() async {
    if (widget.alarm.volumeLock) {
      try {
        await ref.read(volumeLockProvider).lockToMax();
      } catch (e) {
        AppLogger.w('Volume lock unavailable: $e');
      }
    }
  }

  /// A snoozed re-fire re-opens this page as a brand-new widget instance, so
  /// there's no in-memory link back to the original wake_events row — look up
  /// the still-open (not yet dismissed) row for this alarm from the last few
  /// hours instead of always inserting a fresh one.
  Future<void> _recordFired() async {
    try {
      final repo = ref.read(wakeEventRepositoryProvider);
      final recent = await repo.getRecent(limit: 20);
      final cutoff = DateTime.now().subtract(const Duration(hours: 3));
      WakeEvent? open;
      for (final e in recent) {
        if (e.alarmId == widget.alarm.id && e.dismissedAt == null && e.firedAt.isAfter(cutoff)) {
          open = e;
          break;
        }
      }
      final id = open?.id ??
          await repo.insertFired(alarmId: widget.alarm.id, firedAt: DateTime.now());
      _wakeEventId = id;
      if (mounted) setState(() => _snoozeCount = open?.snoozeCount ?? 0);
    } catch (e) {
      AppLogger.w('wake_events insertFired failed: $e');
    }
  }

  /// Stop the ring service + release the volume lock. Only called once the
  /// dismiss task succeeds — leaving the screen otherwise keeps it ringing.
  void _teardown() {
    final volumeLock = widget.alarm.volumeLock ? ref.read(volumeLockProvider) : null;
    () async {
      try {
        await _ringtoneChannel.stopRinging();
      } catch (e) {
        AppLogger.w('Stop ringing failed: $e');
      }
      try {
        await volumeLock?.unlock();
      } catch (e) {
        AppLogger.w('Volume unlock unavailable: $e');
      }
    }();
  }

  bool get _canSnooze =>
      widget.alarm.maxSnoozeCount > 0 && _snoozeCount < widget.alarm.maxSnoozeCount;

  Future<void> _snooze() async {
    if (_snoozing || !_canSnooze) return;
    setState(() => _snoozing = true);
    try {
      await _ringtoneChannel.stopRinging();
    } catch (e) {
      AppLogger.w('Stop ringing (snooze) failed: $e');
    }
    final eventId = _wakeEventId;
    if (eventId != null) {
      try {
        await ref.read(wakeEventRepositoryProvider).incrementSnooze(eventId);
      } catch (e) {
        AppLogger.w('incrementSnooze failed: $e');
      }
    }
    try {
      await ref.read(alarmSchedulerProvider).scheduleOneShot(
            AlarmScheduler.snoozeStableId(widget.alarm.id),
            DateTime.now().add(Duration(minutes: widget.alarm.snoozeMinutes)),
            callback: alarmFireHandler,
          );
    } catch (e) {
      AppLogger.w('Schedule snooze failed: $e');
    }
    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
  }

  void _openSos() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencySosPage()));
  }

  Future<void> _attemptDismiss() async {
    if (_dismissing) return;
    final result = await Navigator.push<TaskResult>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskRunnerPage(config: widget.alarm.dismissTask),
      ),
    );
    if (!mounted) return;
    if (result?.completed ?? false) {
      setState(() => _dismissing = true);
      // Stop the alarm right away — the routine/photo screens below are just
      // regular app UI from here on, not part of the ringing lockdown.
      _teardown();
      await _chainAfterDismiss();
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  /// Ring → Mission (already done by the caller) → Routine → Morning Photo.
  /// Routine/photo are optional bonus steps — any failure here must not trap
  /// the user on this screen (the alarm sound is already stopped).
  Future<void> _chainAfterDismiss() async {
    final eventId = _wakeEventId;
    if (eventId != null) {
      try {
        await ref
            .read(wakeEventRepositoryProvider)
            .recordMissionDismissed(eventId, dismissedAt: DateTime.now());
      } catch (e) {
        AppLogger.w('recordMissionDismissed failed: $e');
      }
    }

    final routineId = widget.alarm.routineId;
    if (routineId != null && mounted) {
      try {
        final routineDone = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => RoutineExecutePage(routineId: routineId)),
        );
        if (routineDone == true && eventId != null) {
          await ref.read(wakeEventRepositoryProvider).markRoutineCompleted(eventId);
        }
      } catch (e) {
        AppLogger.w('Routine chain failed: $e');
      }
    }

    if (mounted) {
      try {
        final saved = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => MorningPhotoCapturePage(alarm: widget.alarm)),
        );
        if (saved == true && eventId != null) {
          await ref.read(wakeEventRepositoryProvider).markPhotoPosted(eventId);
        }
      } catch (e) {
        AppLogger.w('Morning photo chain failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alarm = widget.alarm;
    // Flashbang: alternate the whole screen between black and glaring amber.
    final bright = _strobeBright;
    final bg = bright ? const Color(0xFFF59E0B) : Colors.black;
    final timeColor =
        bright ? Colors.black : Theme.of(context).colorScheme.primary;
    final labelColor = bright ? Colors.black87 : Colors.white70;

    return PopScope(
      canPop: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: bg,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateTimeUtils.formatHm(alarm.hour, alarm.minute),
                    style: TextStyle(
                      color: timeColor,
                      fontSize: 72,
                      fontWeight: FontWeight.w700,
                      // Tabular figures keep the digits from jittering.
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alarm.label.isEmpty ? 'Báo thức' : alarm.label,
                    style: TextStyle(color: labelColor, fontSize: 22),
                  ),
                  const SizedBox(height: 48),
                  FilledButton.icon(
                    onPressed: _dismissing ? null : _attemptDismiss,
                    icon: const Icon(Icons.alarm_off),
                    label: const Text('Tắt báo thức'),
                  ),
                  if (_canSnooze) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _snoozing || _dismissing ? null : _snooze,
                      icon: const Icon(Icons.snooze),
                      label: Text('Báo lại sau ${alarm.snoozeMinutes} phút'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _dismissing ? null : _openSos,
                    icon: const Icon(Icons.sos),
                    label: const Text('Cần trợ giúp'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
