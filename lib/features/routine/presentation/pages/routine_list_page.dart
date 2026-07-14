import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../domain/entities/routine.dart';
import '../providers/routine_providers.dart';
import 'routine_edit_page.dart';

/// Morning Routine list — card per routine (name, step count, enable toggle),
/// FAB to create a new one. Tap opens `RoutineEditPage`.
class RoutineListPage extends ConsumerWidget {
  const RoutineListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routineListProvider);

    Future<void> openEdit(MorningRoutine? existing) async {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RoutineEditPage(existing: existing)),
      );
      ref.invalidate(routineListProvider);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Morning Routine')),
      body: routinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (routines) => routines.isEmpty
            ? const _Empty()
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(routineListProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: routines.length,
                  itemBuilder: (_, i) => _RoutineCard(
                    routine: routines[i],
                    onTap: () => openEdit(routines[i]),
                    onToggle: (v) async {
                      await ref
                          .read(routineRepositoryProvider)
                          .setEnabled(routines[i].id, enabled: v);
                      ref.invalidate(routineListProvider);
                    },
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => openEdit(null),
        icon: const Icon(Icons.add),
        label: const Text('Routine mới'),
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.routine,
    required this.onTap,
    required this.onToggle,
  });

  final MorningRoutine routine;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = routine.isEnabled;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent
                      .withValues(alpha: enabled ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.checklist_rtl_rounded,
                    color: enabled
                        ? AppColors.accent
                        : AppColors.mutedForeground),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(routine.name.isEmpty ? 'Routine' : routine.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${routine.steps.length} bước',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.checklist_rtl_rounded,
                size: 64, color: AppColors.mutedForeground),
            const SizedBox(height: AppSpacing.lg),
            Text('Chưa có routine nào', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Thêm các bước buổi sáng để tự chạy sau khi bạn tắt báo thức.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
