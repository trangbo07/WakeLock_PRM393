import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/platform/system_ringtone_channel.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/custom_ringtone_datasource.dart';
import '../../data/repositories/ringtone_repository_impl.dart';
import '../../domain/entities/ringtone.dart';
import '../../domain/repositories/ringtone_repository.dart';

final systemRingtoneChannelProvider =
    Provider<SystemRingtoneChannel>((ref) => SystemRingtoneChannel());

final ringtoneRepositoryProvider = Provider<RingtoneRepository>((ref) {
  return RingtoneRepositoryImpl(
    ref.watch(systemRingtoneChannelProvider),
    CustomRingtoneDataSource(ref.watch(appDatabaseProvider)),
  );
});

final ringtoneListProvider = FutureProvider<List<Ringtone>>((ref) {
  return ref.watch(ringtoneRepositoryProvider).getRingtones();
});
