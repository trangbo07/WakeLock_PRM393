import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final theme = Theme.of(context);

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
        data: (routines) => routines.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Chưa có routine nào.\nThêm các bước buổi sáng để chạy sau khi tắt báo thức.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(routineListProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: routines.length,
                  itemBuilder: (_, i) {
                    final r = routines[i];
                    return Card(
                      child: ListTile(
                        title: Text(r.name.isEmpty ? 'Routine' : r.name),
                        subtitle: Text('${r.steps.length} bước'),
                        trailing: Switch(
                          value: r.isEnabled,
                          onChanged: (v) async {
                            await ref
                                .read(routineRepositoryProvider)
                                .setEnabled(r.id, enabled: v);
                            ref.invalidate(routineListProvider);
                          },
                        ),
                        onTap: () => openEdit(r),
                      ),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openEdit(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
