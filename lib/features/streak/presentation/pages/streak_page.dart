import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../providers/streak_providers.dart';
import '../widgets/streak_calendar_heatmap.dart';

/// Streak overview — current/longest streak, wake rate, and a calendar
/// heatmap for the current month. Pushed from `HabitPage`.
class StreakPage extends ConsumerWidget {
  const StreakPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(streakProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Streak')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải dữ liệu: $e')),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(wakeEventListProvider),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              _StreakHero(current: stats.current),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _StatCard(
                    icon: Icons.emoji_events,
                    color: AppColors.accent,
                    label: 'Dài nhất',
                    value: '${stats.longest} ngày',
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _StatCard(
                    icon: Icons.wb_sunny,
                    color: const Color(0xFF0EA5E9),
                    label: 'Tỷ lệ đúng giờ',
                    value: '${stats.wakeRatePercent.round()}%',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tháng này',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.md),
                    StreakCalendarHeatmap(
                        month: DateTime.now(),
                        calendarByDay: stats.calendarByDay),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Big current-streak banner with an amber flame gradient.
class _StreakHero extends StatelessWidget {
  const _StreakHero({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department,
              color: Colors.white, size: 48),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$current',
                  style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w900)),
              const Text('ngày liên tiếp',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
