import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/streak_calculator.dart';
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
            padding: const EdgeInsets.all(16),
            children: [
              _StatsRow(stats: stats),
              const SizedBox(height: 24),
              Text('Tháng này', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              StreakCalendarHeatmap(month: DateTime.now(), calendarByDay: stats.calendarByDay),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final StreakStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Streak hiện tại', value: '${stats.current} ngày')),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Streak dài nhất', value: '${stats.longest} ngày')),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(label: 'Tỷ lệ thức đúng giờ', value: '${stats.wakeRatePercent.round()}%'),
        ),
      ],
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
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
