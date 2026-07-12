import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../../../task/domain/entities/dismiss_task.dart';
import '../../domain/entities/alarm.dart';

/// A single alarm row in the home list, shown as a card: big time, label +
/// repeat schedule, the dismiss-task type, and an enable/disable switch.
class AlarmTile extends StatelessWidget {
  const AlarmTile({
    super.key,
    required this.alarm,
    this.onToggle,
    this.onTap,
  });

  final Alarm alarm;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateTimeUtils.formatHm(alarm.hour, alarm.minute);
    final repeat = alarm.isOneShot
        ? 'Một lần'
        : alarm.repeatDays
            .map((d) => d.shortLabel)
            .join(' ');
    // Dim disabled alarms so the enabled ones stand out at a glance.
    final opacity = alarm.isEnabled ? 1.0 : 0.45;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: opacity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        time,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [if (alarm.label.isNotEmpty) alarm.label, repeat]
                            .join(' · '),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      _TaskChip(type: alarm.dismissTask.type),
                    ],
                  ),
                ),
              ),
              Switch(value: alarm.isEnabled, onChanged: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskChip extends StatelessWidget {
  const _TaskChip({required this.type});

  final DismissTaskType type;

  static const Map<DismissTaskType, IconData> _icons = {
    DismissTaskType.none: Icons.touch_app,
    DismissTaskType.math: Icons.calculate,
    DismissTaskType.shake: Icons.vibration,
    DismissTaskType.walk: Icons.directions_walk,
    DismissTaskType.photo: Icons.camera_alt,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icons[type], size: 16, color: theme.colorScheme.tertiary),
        const SizedBox(width: 4),
        Text(type.label, style: theme.textTheme.labelMedium),
      ],
    );
  }
}
