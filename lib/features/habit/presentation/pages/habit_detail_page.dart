import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../streak/presentation/widgets/streak_calendar_heatmap.dart';
import '../../domain/entities/habit.dart';
import '../../domain/habit_streak_calculator.dart';
import '../providers/habit_providers.dart';
import '../widgets/habit_icon_catalog.dart';
import 'habit_edit_page.dart';

/// One habit's check-in calendar + streak numbers.
class HabitDetailPage extends ConsumerWidget {
  const HabitDetailPage({super.key, required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinsAsync = ref.watch(habitCheckinsProvider(habit.id));
    final theme = Theme.of(context);
    final color = HabitIconCatalog.colorFor(habit.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name.isEmpty ? 'Thói quen' : habit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HabitEditPage(existing: habit)),
              );
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: checkinsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (checkins) {
          final stats = HabitStreakCalculator().calculate(habit, checkins);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  HabitIconBadge(iconKey: habit.icon, color: color, size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.name.isEmpty ? 'Thói quen' : habit.name,
                            style: theme.textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            habit.frequencyType.label,
                            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _StreakBanner(currentStreak: stats.currentStreak),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.emoji_events_outlined,
                      label: 'Streak dài nhất',
                      value: '${stats.longestStreak}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Tỷ lệ hoàn thành',
                      value: '${stats.completionRatePercent.round()}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.calendar_month_outlined,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text('Tháng này', style: theme.textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              StreakCalendarHeatmap(month: DateTime.now(), calendarByDay: stats.calendarByDay),
            ],
          );
        },
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.currentStreak});

  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flames = currentStreak.clamp(0, 5);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Streak hiện tại', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text('$currentStreak ngày',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              for (var i = 0; i < (flames == 0 ? 1 : flames); i++)
                Icon(
                  Icons.local_fire_department_rounded,
                  color: currentStreak == 0
                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                      : AppColors.primary,
                  size: 28,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
