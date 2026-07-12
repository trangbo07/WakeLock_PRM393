import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/alarm_providers.dart';
import '../widgets/alarm_tile.dart';

/// Home screen: the list of configured alarms with a FAB to add a new one.
class AlarmListPage extends ConsumerWidget {
  const AlarmListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmsAsync = ref.watch(alarmListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.settings),
          ),
        ],
      ),
      body: alarmsAsync.when(
        data: (alarms) => alarms.isEmpty
            ? const Center(child: Text('Chưa có báo thức nào'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(alarmListProvider),
                child: ListView.builder(
                  itemCount: alarms.length,
                  itemBuilder: (_, i) => AlarmTile(
                    alarm: alarms[i],
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        AppRouter.alarmEdit,
                        arguments: alarms[i],
                      );
                      ref.invalidate(alarmListProvider);
                    },
                    onToggle: (enabled) async {
                      await ref
                          .read(alarmRepositoryProvider)
                          .setEnabled(alarms[i].id, enabled: enabled);
                      ref.invalidate(alarmListProvider);
                    },
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRouter.alarmEdit);
          ref.invalidate(alarmListProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
