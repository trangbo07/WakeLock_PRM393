import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/emergency_contact_local_datasource.dart';
import '../../data/repositories/local_emergency_contact_repository.dart';
import '../../domain/entities/emergency_contact.dart';
import '../../domain/repositories/emergency_contact_repository.dart';

final emergencyContactLocalDataSourceProvider = Provider<EmergencyContactLocalDataSource>(
  (ref) => EmergencyContactLocalDataSource(ref.watch(appDatabaseProvider)),
);

final emergencyContactRepositoryProvider = Provider<EmergencyContactRepository>(
  (ref) => LocalEmergencyContactRepository(ref.watch(emergencyContactLocalDataSourceProvider)),
);

final emergencyContactListProvider = FutureProvider<List<EmergencyContact>>(
  (ref) => ref.watch(emergencyContactRepositoryProvider).getContacts(),
);
