import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/routine_providers.dart';

/// Morning Routine list (STARTER SCAFFOLD for Dev 1).
///
/// Data layer is wired end-to-end (routineListProvider → repository → SQLite).
/// Replace this UI with the real design when the Routine screenshot arrives;
/// keep reading from routineListProvider and write via routineRepositoryProvider.
class RoutineListPage extends ConsumerWidget {
  const RoutineListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routineListProvider);
    final theme = Theme.of(context);

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
                  itemCount: routines.length,
                  itemBuilder: (_, i) {
                    final r = routines[i];
                    return ListTile(
                      title: Text(r.name.isEmpty ? 'Routine' : r.name),
                      subtitle: Text('${r.steps.length} bước'),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}
