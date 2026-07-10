import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/alarm_local_cache_datasource.dart';
import '../../data/datasources/alarm_remote_datasource.dart';
import '../../data/repositories/alarm_repository_impl.dart';
import '../../data/repositories/in_memory_alarm_repository.dart';
import '../../domain/entities/alarm.dart';
import '../../domain/repositories/alarm_repository.dart';

/// DI wiring for the alarm feature.
final alarmRemoteDataSourceProvider = Provider<AlarmRemoteDataSource>((ref) {
  return AlarmRemoteDataSource(ref.watch(supabaseClientProvider));
});

final alarmLocalCacheProvider = Provider<AlarmLocalCacheDataSource>((ref) {
  return AlarmLocalCacheDataSource();
});

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  // No Supabase configured -> serve demo data so the UI is viewable offline.
  if (!Env.isConfigured) {
    return InMemoryAlarmRepository.demo();
  }
  return AlarmRepositoryImpl(
    ref.watch(alarmRemoteDataSourceProvider),
    ref.watch(alarmLocalCacheProvider),
  );
});

/// Async list of alarms shown on the home screen. Invalidate to refresh.
final alarmListProvider = FutureProvider<List<Alarm>>((ref) {
  return ref.watch(alarmRepositoryProvider).getAlarms();
});
