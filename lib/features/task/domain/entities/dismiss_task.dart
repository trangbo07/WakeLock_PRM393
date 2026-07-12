import 'package:equatable/equatable.dart';

/// The kind of task a user must complete to silence a ringing alarm.
enum DismissTaskType {
  /// Just tap to dismiss (easy mode).
  none('Chạm tắt'),

  /// Solve math problems.
  math('Giải toán'),

  /// Shake the phone N times.
  shake('Lắc máy'),

  /// Scan a specific QR code (e.g. taped in the bathroom).
  qrScan('Quét QR'),

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
    this.qrPayload,
    this.photoTag,
  });

  final DismissTaskType type;

  /// math: number of problems / digit size.
  final int difficulty;

  /// shake: required number of shakes.
  final int shakeCount;

  /// qrScan: expected decoded QR value.
  final String? qrPayload;

  /// photo: expected label / hint for the target object.
  final String? photoTag;

  static const DismissTaskConfig easy =
      DismissTaskConfig(type: DismissTaskType.none);

  DismissTaskConfig copyWith({
    DismissTaskType? type,
    int? difficulty,
    int? shakeCount,
    String? qrPayload,
    String? photoTag,
  }) {
    return DismissTaskConfig(
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      shakeCount: shakeCount ?? this.shakeCount,
      qrPayload: qrPayload ?? this.qrPayload,
      photoTag: photoTag ?? this.photoTag,
    );
  }

  @override
  List<Object?> get props => [type, difficulty, shakeCount, qrPayload, photoTag];
}
