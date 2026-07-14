import 'package:equatable/equatable.dart';

/// One row per alarm firing — the source of truth for streak/dashboard stats.
///
/// `wakeSuccess` follows the product rule: the dismiss Mission was completed
/// within 10 minutes of [firedAt]. Routine/photo completion are bonus signals
/// (stored for the dashboard) but do NOT gate `wakeSuccess`/streak.
class WakeEvent extends Equatable {
  const WakeEvent({
    required this.id,
    required this.firedAt,
    this.alarmId,
    this.dismissedAt,
    this.missionCompleted = false,
    this.routineCompleted = false,
    this.photoPosted = false,
    this.wakeSuccess = false,
    this.snoozeCount = 0,
  });

  final String id;
  final String? alarmId;
  final DateTime firedAt;
  final DateTime? dismissedAt;
  final bool missionCompleted;
  final bool routineCompleted;
  final bool photoPosted;
  final bool wakeSuccess;
  final int snoozeCount;

  /// The window (from [firedAt]) within which dismissing the Mission still
  /// counts as "woke on time" for streak purposes.
  static const Duration onTimeWindow = Duration(minutes: 10);

  WakeEvent copyWith({
    DateTime? dismissedAt,
    bool? missionCompleted,
    bool? routineCompleted,
    bool? photoPosted,
    bool? wakeSuccess,
    int? snoozeCount,
  }) =>
      WakeEvent(
        id: id,
        alarmId: alarmId,
        firedAt: firedAt,
        dismissedAt: dismissedAt ?? this.dismissedAt,
        missionCompleted: missionCompleted ?? this.missionCompleted,
        routineCompleted: routineCompleted ?? this.routineCompleted,
        photoPosted: photoPosted ?? this.photoPosted,
        wakeSuccess: wakeSuccess ?? this.wakeSuccess,
        snoozeCount: snoozeCount ?? this.snoozeCount,
      );

  @override
  List<Object?> get props => [
        id,
        alarmId,
        firedAt,
        dismissedAt,
        missionCompleted,
        routineCompleted,
        photoPosted,
        wakeSuccess,
        snoozeCount,
      ];
}
