import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/morning_photo_local_datasource.dart';
import '../../data/repositories/local_morning_photo_repository.dart';
import '../../domain/entities/morning_photo.dart';
import '../../domain/repositories/morning_photo_repository.dart';

/// DI for the morning-photo feature.
final morningPhotoLocalDataSourceProvider =
    Provider<MorningPhotoLocalDataSource>(
  (ref) => MorningPhotoLocalDataSource(ref.watch(appDatabaseProvider)),
);

final morningPhotoRepositoryProvider = Provider<MorningPhotoRepository>(
  (ref) =>
      LocalMorningPhotoRepository(ref.watch(morningPhotoLocalDataSourceProvider)),
);

/// All captured photos, newest first. Invalidate after capture/post to refresh.
final morningPhotoListProvider = FutureProvider<List<MorningPhoto>>(
  (ref) => ref.watch(morningPhotoRepositoryProvider).getPhotos(),
);
