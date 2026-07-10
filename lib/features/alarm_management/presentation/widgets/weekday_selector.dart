import 'package:flutter/material.dart';

import '../../domain/entities/weekday.dart';

/// Row of toggle chips for choosing which days an alarm repeats.
class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<Weekday> selected;
  final ValueChanged<Set<Weekday>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        for (final day in Weekday.values)
          FilterChip(
            label: Text(day.shortLabel),
            selected: selected.contains(day),
            onSelected: (on) {
              final next = {...selected};
              if (on) {
                next.add(day);
              } else {
                next.remove(day);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}
