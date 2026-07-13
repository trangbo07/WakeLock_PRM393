import '../entities/morning_photo.dart';

/// Persistence contract for locally-captured morning photos.
/// [getUnposted] + [markPosted] are the seam Dev 2's feed uses to publish.
abstract class MorningPhotoRepository {
  Future<List<MorningPhoto>> getPhotos();
  Future<MorningPhoto?> getById(String id);
  Future<void> save(MorningPhoto photo);
  Future<void> delete(String id);

  /// Photos captured but not yet uploaded to the cloud feed.
  Future<List<MorningPhoto>> getUnposted();

  /// Mark a photo as posted after Dev 2 uploads it (stores the Firestore id).
  Future<void> markPosted(String id, String remoteId);
}
