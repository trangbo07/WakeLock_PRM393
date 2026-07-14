import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../ai_coach/presentation/pages/ai_coach_page.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../emergency/presentation/pages/emergency_contacts_page.dart';
import '../../../morning_photo/presentation/pages/morning_photo_page.dart';
import '../../../routine/presentation/pages/routine_list_page.dart';
import '../../../streak/presentation/pages/streak_page.dart';
import '../../domain/entities/habit.dart';
import '../../domain/habit_streak_calculator.dart';
import '../providers/habit_providers.dart';
import '../widgets/habit_icon_catalog.dart';
import 'habit_detail_page.dart';
import 'habit_edit_page.dart';

/// Habit tab root: today's habits with quick check-in, + entry points to the
/// rest of the "Wake & Personal" feature set (Streak, Routine, Morning Photo,
/// Dashboard, AI Coach, Emergency contacts) that don't have their own tab.
class HabitListPage extends ConsumerWidget {
  const HabitListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitListProvider);
    final theme = Theme.of(context);
    final today = DateTime.now();

    Future<void> openEdit(Habit? existing) async {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HabitEditPage(existing: existing)),
      );
      ref.invalidate(habitListProvider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Thói quen')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const _NavCardRow(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.today_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Hôm nay', style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: 4),
          habitsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(padding: const EdgeInsets.all(24), child: Text('Lỗi: $e')),
            data: (habits) {
              final due = habits.where((h) => h.isActive && h.isDueOn(today)).toList();
              if (due.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.self_improvement_rounded,
                          size: 56, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text(
                        'Chưa có thói quen nào cho hôm nay.\nNhấn nút + để thêm.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [for (final h in due) _HabitTile(habit: h, onOpenEdit: openEdit)],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openEdit(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HabitTile extends ConsumerWidget {
  const _HabitTile({required this.habit, required this.onOpenEdit});

  final Habit habit;
  final ValueChanged<Habit> onOpenEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateKey = todayDateKey();
    final checkedAsync = ref.watch(habitCheckinsProvider(habit.id));
    final color = HabitIconCatalog.colorFor(habit.color);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HabitDetailPage(habit: habit)),
            );
            ref.invalidate(habitListProvider);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                HabitIconBadge(iconKey: habit.icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name.isEmpty ? 'Thói quen' : habit.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        habit.frequencyType.label,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                checkedAsync.when(
                  loading: () => const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) => const Icon(Icons.error_outline),
                  data: (checkins) {
                    final checked = checkins.any((c) => c.date == dateKey);
                    final stats = HabitStreakCalculator().calculate(habit, checkins);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (stats.currentStreak > 0) ...[
                          _StreakPill(count: stats.currentStreak),
                          const SizedBox(width: 4),
                        ],
                        IconButton(
                          icon: Icon(
                            checked ? Icons.check_circle_rounded : Icons.circle_outlined,
                            color: checked ? const Color(0xFF16A34A) : null,
                          ),
                          onPressed: () async {
                            final repo = ref.read(habitRepositoryProvider);
                            if (checked) {
                              await repo.uncheckin(habit.id, date: dateKey);
                            } else {
                              await repo.checkin(habit.id, date: dateKey);
                            }
                            ref.invalidate(habitCheckinsProvider(habit.id));
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: const TextStyle(
                color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _NavCardRow extends StatelessWidget {
  const _NavCardRow();

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, Color, String, WidgetBuilder)>[
      (Icons.local_fire_department_rounded, const Color(0xFFF59E0B), 'Streak',
          (_) => const StreakPage()),
      (Icons.checklist_rtl_rounded, const Color(0xFF6366F1), 'Routine',
          (_) => const RoutineListPage()),
      (Icons.camera_alt_rounded, const Color(0xFFEC4899), 'Ảnh sáng',
          (_) => const MorningPhotoPage()),
      (Icons.bar_chart_rounded, const Color(0xFF0EA5E9), 'Dashboard',
          (_) => const DashboardPage()),
      (Icons.psychology_rounded, const Color(0xFF8B5CF6), 'AI Coach',
          (_) => const AiCoachPage()),
      (Icons.sos_rounded, const Color(0xFFEF4444), 'Khẩn cấp',
          (_) => const EmergencyContactsPage()),
    ];
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (icon, color, label, builder) = items[i];
          return _NavCard(
            icon: icon,
            color: color,
            label: label,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: builder)),
          );
        },
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
