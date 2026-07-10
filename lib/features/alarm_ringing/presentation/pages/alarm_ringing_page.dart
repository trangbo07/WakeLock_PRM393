import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../../../task/domain/entities/dismiss_task.dart';
import '../../../task/domain/entities/task_result.dart';
import '../../../task/presentation/task_runner_page.dart';

/// Full-screen, hard-to-escape alarm screen shown when an alarm fires.
///
/// [PopScope] blocks the Android back button; the Home button is handled at the
/// native layer (full-screen intent + overlay). The alarm can only be silenced
/// by completing [dismissTask].
class AlarmRingingPage extends StatelessWidget {
  const AlarmRingingPage({
    super.key,
    required this.alarmId,
    required this.label,
    required this.hour,
    required this.minute,
    required this.dismissTask,
  });

  final String alarmId;
  final String label;
  final int hour;
  final int minute;
  final DismissTaskConfig dismissTask;

  Future<void> _attemptDismiss(BuildContext context) async {
    final result = await Navigator.push<TaskResult>(
      context,
      MaterialPageRoute(builder: (_) => TaskRunnerPage(config: dismissTask)),
    );
    if (!context.mounted) return;
    if (result?.completed ?? false) {
      // TODO: stop ringtone, unlock volume, stop foreground service, close overlay.
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  DateTimeUtils.formatHm(hour, minute),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary, // amber
                    fontSize: 72,
                    fontWeight: FontWeight.w700,
                    // Tabular figures keep the digits from jittering as time ticks.
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label.isEmpty ? 'Báo thức' : label,
                  style: const TextStyle(color: Colors.white70, fontSize: 22),
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: () => _attemptDismiss(context),
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
