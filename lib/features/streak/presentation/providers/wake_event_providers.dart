import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/wake_event_local_datasource.dart';
import '../../data/repositories/local_wake_event_repository.dart';
import '../../domain/repositories/wake_event_repository.dart';

/// DI for wake_events. `alarm_ringing` imports [wakeEventRepositoryProvider]
/// to write rows as an alarm fires/is dismissed/is snoozed (both Dev-1-owned
/// features, so this is not a cross-owner file edit).
final wakeEventLocalDataSourceProvider = Provider<WakeEventLocalDataSource>(
  (ref) => WakeEventLocalDataSource(ref.watch(appDatabaseProvider)),
);

final wakeEventRepositoryProvider = Provider<WakeEventRepository>(
  (ref) => LocalWakeEventRepository(ref.watch(wakeEventLocalDataSourceProvider)),
);
