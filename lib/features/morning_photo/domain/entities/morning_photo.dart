import 'package:equatable/equatable.dart';

/// Who a morning photo is shared with. Stored as the enum name in
/// morning_photos.privacy (SQLite).
enum PhotoPrivacy { private, friends, close, selected }

/// A photo captured right after waking. Saved locally first (`posted=false`);
/// Dev 2's feed later uploads it to Storage/Firestore and sets [remoteId].
class MorningPhoto extends Equatable {
  const MorningPhoto({
    required this.id,
    required this.path,
    required this.createdAt,
    this.caption = '',
    this.mood,
    this.weather,
    this.wakeTime,
    this.alarmTime,
    this.privacy = PhotoPrivacy.private,
    this.posted = false,
    this.remoteId,
  });

  final String id;

  /// Absolute path of the captured image on device.
  final String path;
  final String caption;
  final String? mood;
  final String? weather;

  /// When the user actually woke (dismissed the alarm) vs the scheduled time.
  final DateTime? wakeTime;
  final DateTime? alarmTime;

  final PhotoPrivacy privacy;

  /// True once uploaded to the cloud feed (set by Dev 2).
  final bool posted;

  /// Firestore post id after upload (null until posted).
  final String? remoteId;

  final DateTime createdAt;

  MorningPhoto copyWith({
    String? caption,
    String? mood,
    String? weather,
    PhotoPrivacy? privacy,
    bool? posted,
    String? remoteId,
  }) =>
      MorningPhoto(
        id: id,
        path: path,
        createdAt: createdAt,
        wakeTime: wakeTime,
        alarmTime: alarmTime,
        caption: caption ?? this.caption,
        mood: mood ?? this.mood,
        weather: weather ?? this.weather,
        privacy: privacy ?? this.privacy,
        posted: posted ?? this.posted,
        remoteId: remoteId ?? this.remoteId,
      );

  @override
  List<Object?> get props =>
      [id, path, caption, mood, weather, wakeTime, alarmTime, privacy, posted, remoteId, createdAt];
}
