import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/ringtone_repository_impl.dart';
import '../../domain/entities/ringtone.dart';
import '../../domain/repositories/ringtone_repository.dart';

final ringtoneRepositoryProvider = Provider<RingtoneRepository>((ref) {
  return RingtoneRepositoryImpl();
});

final ringtoneListProvider = FutureProvider<List<Ringtone>>((ref) {
  return ref.watch(ringtoneRepositoryProvider).getRingtones();
});
