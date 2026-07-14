import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Single-month calendar heatmap: green = at least one on-time wake that day,
/// red = alarm fired but missed, muted = no data. Shared by `streak_page.dart`
/// and `dashboard_page.dart` so both stay visually consistent.
class StreakCalendarHeatmap extends StatelessWidget {
  const StreakCalendarHeatmap({
    super.key,
    required this.month,
    required this.calendarByDay,
  });

  /// Any date within the month to render (day component is ignored).
  final DateTime month;

  /// Local day (midnight) -> whether that day had a successful wake.
  final Map<DateTime, bool> calendarByDay;

  static const _weekdayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = first.weekday - 1; // Mon=1..Sun=7 -> 0-based

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (final l in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(l,
                      style: const TextStyle(color: AppColors.mutedForeground, fontSize: 11)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: leadingBlanks + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingBlanks) return const SizedBox.shrink();
            final day = index - leadingBlanks + 1;
            final date = DateTime(month.year, month.month, day);
            final hasData = calendarByDay.containsKey(date);
            final win = calendarByDay[date] == true;
            final color = !hasData
                ? AppColors.surfaceMuted
                : win
                    ? const Color(0xFF16A34A)
                    : AppColors.destructive;
            return Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 11,
                  color: hasData ? Colors.white : AppColors.mutedForeground,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
