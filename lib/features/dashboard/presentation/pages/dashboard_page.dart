import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
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
    final theme = Theme.of(context);

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
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Thức đúng giờ (7 ngày)',
                      value: '${stats.wakeRate7dPercent.round()}%',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Thức đúng giờ (30 ngày)',
                      value: '${stats.wakeRate30dPercent.round()}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Thời gian dậy TB',
                      value: '${stats.avgDismissDelayMinutes.round()} phút',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Số lần báo lại TB',
                      value: stats.avgSnoozeCount.toStringAsFixed(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Hoàn thành thói quen',
                      value: '${stats.habitCompletionRatePercent.round()}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Tỷ lệ thức đúng giờ theo tuần', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(height: 180, child: _WeeklyBarChart(stats: stats)),
              const SizedBox(height: 24),
              Text('Streak calendar (tháng này)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              streakAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Lỗi: $e'),
                data: (streak) => StreakCalendarHeatmap(
                  month: DateTime.now(),
                  calendarByDay: streak.calendarByDay,
                ),
              ),
            ],
          ),
        ),
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
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= weekly.length) return const SizedBox.shrink();
                final w = weekly[i].weekStart;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${w.day}/${w.month}', style: const TextStyle(fontSize: 10)),
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
                  color: AppColors.primary,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
