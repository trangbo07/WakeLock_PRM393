import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/routine_local_datasource.dart';
import '../../data/repositories/local_routine_repository.dart';
import '../../domain/entities/routine.dart';
import '../../domain/repositories/routine_repository.dart';

/// DI for the routine feature. Mirrors alarm_providers.dart.
final routineLocalDataSourceProvider = Provider<RoutineLocalDataSource>(
  (ref) => RoutineLocalDataSource(ref.watch(appDatabaseProvider)),
);

final routineRepositoryProvider = Provider<RoutineRepository>(
  (ref) => LocalRoutineRepository(ref.watch(routineLocalDataSourceProvider)),
);

/// All routines (newest first). Invalidate after create/edit/delete to refresh.
final routineListProvider = FutureProvider<List<MorningRoutine>>(
  (ref) => ref.watch(routineRepositoryProvider).getRoutines(),
);
