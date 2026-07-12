import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/alarm_local_datasource.dart';
import '../../data/repositories/local_alarm_repository.dart';
import '../../domain/entities/alarm.dart';
import '../../domain/repositories/alarm_repository.dart';

/// DI wiring for the alarm feature.
final alarmLocalDataSourceProvider = Provider<AlarmLocalDataSource>((ref) {
  return AlarmLocalDataSource(ref.watch(appDatabaseProvider));
});

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  return LocalAlarmRepository(ref.watch(alarmLocalDataSourceProvider));
});

/// Async list of alarms shown on the home screen. Invalidate to refresh.
final alarmListProvider = FutureProvider<List<Alarm>>((ref) {
  return ref.watch(alarmRepositoryProvider).getAlarms();
});
