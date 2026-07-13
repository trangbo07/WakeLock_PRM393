import '../../domain/entities/morning_photo.dart';
import '../../domain/repositories/morning_photo_repository.dart';
import '../datasources/morning_photo_local_datasource.dart';

/// SQLite-backed [MorningPhotoRepository].
class LocalMorningPhotoRepository implements MorningPhotoRepository {
  LocalMorningPhotoRepository(this._ds);

  final MorningPhotoLocalDataSource _ds;

  @override
  Future<List<MorningPhoto>> getPhotos() => _ds.fetchAll();

  @override
  Future<MorningPhoto?> getById(String id) => _ds.fetchById(id);

  @override
  Future<void> save(MorningPhoto photo) => _ds.upsert(photo);

  @override
  Future<void> delete(String id) => _ds.delete(id);

  @override
  Future<List<MorningPhoto>> getUnposted() => _ds.fetchUnposted();

  @override
  Future<void> markPosted(String id, String remoteId) =>
      _ds.markPosted(id, remoteId);
}
