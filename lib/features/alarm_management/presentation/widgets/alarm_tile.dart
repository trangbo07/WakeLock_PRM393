import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../../domain/entities/alarm.dart';

/// A single alarm row in the home list.
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
    final time = DateTimeUtils.formatHm(alarm.hour, alarm.minute);
    final repeat = alarm.isOneShot
        ? 'Một lần'
        : alarm.repeatDays.map((d) => d.shortLabel).join(' ');

    return ListTile(
      onTap: onTap,
      title: Text(time, style: Theme.of(context).textTheme.headlineMedium),
      subtitle: Text(
        [if (alarm.label.isNotEmpty) alarm.label, repeat].join(' · '),
      ),
      trailing: Switch(
        value: alarm.isEnabled,
        onChanged: onToggle,
      ),
    );
  }
}
