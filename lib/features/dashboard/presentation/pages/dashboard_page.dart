import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../streak/presentation/providers/streak_providers.dart';
import '../../../streak/presentation/widgets/streak_calendar_heatmap.dart';
import '../../domain/dashboard_stats.dart';
import '../providers/dashboard_providers.dart';

/// Analytics: wake-rate bar chart (last 6 weeks), streak calendar heatmap,
/// and summary cards (avg dismiss delay, avg snooze count, habit completion).
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final streakAsync = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (stats) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(streakProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  _StatCard(
                    icon: Icons.wb_sunny,
                    color: const Color(0xFF0EA5E9),
                    label: 'Thức đúng giờ\n7 ngày',
                    value: '${stats.wakeRate7dPercent.round()}%',
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _StatCard(
                    icon: Icons.calendar_month,
                    color: AppColors.accent,
                    label: 'Thức đúng giờ\n30 ngày',
                    value: '${stats.wakeRate30dPercent.round()}%',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _StatCard(
                    icon: Icons.timer_outlined,
                    color: AppColors.primary,
                    label: 'Dậy TB',
                    value: '${stats.avgDismissDelayMinutes.round()}p',
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _StatCard(
                    icon: Icons.snooze,
                    color: const Color(0xFF8B5CF6),
                    label: 'Báo lại TB',
                    value: stats.avgSnoozeCount.toStringAsFixed(1),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _StatCard(
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF22C55E),
                    label: 'Thói quen',
                    value: '${stats.habitCompletionRatePercent.round()}%',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _Section(
                title: 'Tỷ lệ thức đúng giờ theo tuần',
                child: SizedBox(
                  height: 180,
                  child: stats.weeklyWakeRates.any((w) => w.ratePercent > 0)
                      ? _WeeklyBarChart(stats: stats)
                      : const _ChartEmpty(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _Section(
                title: 'Streak tháng này',
                child: streakAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Lỗi: $e'),
                  data: (streak) => StreakCalendarHeatmap(
                    month: DateTime.now(),
                    calendarByDay: streak.calendarByDay,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Titled card wrapper for a dashboard section.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 40, color: AppColors.mutedForeground),
          SizedBox(height: AppSpacing.sm),
          Text('Chưa có dữ liệu thức dậy',
              style: TextStyle(color: AppColors.mutedForeground)),
          SizedBox(height: 2),
          Text('Hoàn thành báo thức để xem thống kê tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.mutedForeground, fontSize: 12)),
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final weekly = stats.weeklyWakeRates;
    return BarChart(
      BarChartData(
        maxY: 100,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (v) =>
              const FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= weekly.length) return const SizedBox.shrink();
                final w = weekly[i].weekStart;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${w.day}/${w.month}',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.mutedForeground)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < weekly.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: weekly[i].ratePercent,
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.sm)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: AppColors.surfaceMuted,
                  ),
                ),
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
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
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
            const SizedBox(height: AppSpacing.sm),
            Text(value,
                maxLines: 1,
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
