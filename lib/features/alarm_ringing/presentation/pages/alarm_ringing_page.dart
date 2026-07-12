import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/logger.dart';
import '../../../alarm_management/domain/entities/alarm.dart';
import '../../../ringtone/presentation/providers/ringtone_providers.dart';
import '../../../task/domain/entities/task_result.dart';
import '../../../task/presentation/task_runner_page.dart';

/// Full-screen, hard-to-escape dismiss screen.
///
/// The looping alarm sound is played by the native [AlarmSoundService], so it
/// keeps ringing even if this screen is closed — the screen is the dismiss UI.
/// It pins/locks the volume and keeps the screen on (via the volume channel's
/// window flags), blocks Back ([PopScope]), and stops the ring service only
/// when the dismiss task succeeds.
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

  @override
  void initState() {
    super.initState();
    _lockDown();
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
