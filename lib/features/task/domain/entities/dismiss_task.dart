import 'package:equatable/equatable.dart';

/// The kind of task a user must complete to silence a ringing alarm.
enum DismissTaskType {
  /// Just tap to dismiss (easy mode).
  none('Chạm tắt'),

  /// Solve math problems.
  math('Giải toán'),

  /// Shake the phone N times.
  shake('Lắc máy'),

  /// Walk a target distance (in meters) measured from step motion.
  walk('Đi bộ'),

  /// Take a photo of a target (e.g. a plant).
  photo('Chụp ảnh');

  const DismissTaskType(this.label);

  /// Short Vietnamese label shown in pickers and the alarm list.
  final String label;
}

/// Configuration for the chosen dismiss task. Only the fields relevant to
/// [type] are used.
class DismissTaskConfig extends Equatable {
  const DismissTaskConfig({
    this.type = DismissTaskType.math,
    this.difficulty = 3,
    this.shakeCount = 50,
    this.walkMeters = 30,
    this.photoTag,
  });

  final DismissTaskType type;

  /// math: number of problems / digit size.
  final int difficulty;

  /// shake: required number of shakes.
  final int shakeCount;

  /// walk: target distance to walk, in meters.
  final int walkMeters;

  /// photo: expected label / hint for the target object.
  final String? photoTag;

  static const DismissTaskConfig easy =
      DismissTaskConfig(type: DismissTaskType.none);

  DismissTaskConfig copyWith({
    DismissTaskType? type,
    int? difficulty,
    int? shakeCount,
    int? walkMeters,
    String? photoTag,
  }) {
    return DismissTaskConfig(
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      shakeCount: shakeCount ?? this.shakeCount,
      walkMeters: walkMeters ?? this.walkMeters,
      photoTag: photoTag ?? this.photoTag,
    );
  }

  @override
  List<Object?> get props =>
      [type, difficulty, shakeCount, walkMeters, photoTag];
}
