import 'package:equatable/equatable.dart';

import '../../../task/domain/entities/dismiss_task.dart';
import 'weekday.dart';

/// Persistence-agnostic domain model of a single alarm.
class Alarm extends Equatable {
  const Alarm({
    required this.id,
    required this.label,
    required this.hour,
    required this.minute,
    this.repeatDays = const {},
    this.isEnabled = true,
    this.ringtoneId = 'default',
    this.vibrate = true,
    this.volumeLock = true,
    this.escalateVolume = true,
    this.flashlight = true,
    this.dismissTask = const DismissTaskConfig(),
  });

  final String id;
  final String label;

  /// 0–23.
  final int hour;

  /// 0–59.
  final int minute;

  /// Empty set => one-shot alarm (fires once).
  final Set<Weekday> repeatDays;

  final bool isEnabled;
  final String ringtoneId;
  final bool vibrate;

  /// Block the system volume-down key while ringing.
  final bool volumeLock;

  /// Gradually increase volume from low to max.
  final bool escalateVolume;

  /// Strobe the camera flashlight while ringing ("flashbang").
  final bool flashlight;

  /// Task the user must complete to turn the alarm off.
  final DismissTaskConfig dismissTask;

  bool get isOneShot => repeatDays.isEmpty;

  Alarm copyWith({
    String? id,
    String? label,
    int? hour,
    int? minute,
    Set<Weekday>? repeatDays,
    bool? isEnabled,
    String? ringtoneId,
    bool? vibrate,
    bool? volumeLock,
    bool? escalateVolume,
    bool? flashlight,
    DismissTaskConfig? dismissTask,
  }) {
    return Alarm(
      id: id ?? this.id,
      label: label ?? this.label,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDays: repeatDays ?? this.repeatDays,
      isEnabled: isEnabled ?? this.isEnabled,
      ringtoneId: ringtoneId ?? this.ringtoneId,
      vibrate: vibrate ?? this.vibrate,
      volumeLock: volumeLock ?? this.volumeLock,
      escalateVolume: escalateVolume ?? this.escalateVolume,
      flashlight: flashlight ?? this.flashlight,
      dismissTask: dismissTask ?? this.dismissTask,
    );
  }

  @override
  List<Object?> get props => [
        id,
        label,
        hour,
        minute,
        repeatDays,
        isEnabled,
        ringtoneId,
        vibrate,
        volumeLock,
        escalateVolume,
        flashlight,
        dismissTask,
      ];
}
